import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:super_app/core/services/infrastructure/python_worker_service.dart';
import 'package:super_app/core/services/media/lyrics_service.dart';
import 'package:super_app/features/home/data/models/track_model.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YoutubeDownloadService {
  final YoutubeExplode _yt = YoutubeExplode();
  final LyricsService _lyricsService;
  final PythonWorkerService _workerService;

  static final _illegalChars = RegExp(r'[<>:"/\\|?*]');
  static final _controlChars = RegExp(r'[\x00-\x1F\x7F]');

  YoutubeDownloadService(this._lyricsService, this._workerService);

  void dispose() {
    _yt.close();
  }

  Future<TrackModel?> downloadAndConvert({
    required String url,
    String? title,
    String? artist,
    String? album,
    String? albumArtUrl,
    Duration? trackDuration,
    Function(String stage, double progress)? onProgress,
  }) async {
    try {
      final videoId = VideoId.parseVideoId(url);
      if (videoId == null) throw Exception('URL YouTube tidak valid');

      onProgress?.call('Fetching metadata...', 0.05);

      String finalTitle = title ?? 'YouTube Audio';
      String finalArtist = artist ?? 'Unknown Artist';
      String finalAlbum = album ?? 'YouTube Download';
      String finalThumbnail = albumArtUrl ?? '';
      String finalDuration = _formatDuration(trackDuration);

      if (title == null || artist == null || albumArtUrl == null) {
        Video? video;
        try {
          video = await _yt.videos
              .get(videoId)
              .timeout(const Duration(seconds: 10));
          finalTitle = title ?? video.title;
          finalArtist = artist ?? video.author;
          finalAlbum = album ?? video.author;
          finalThumbnail = albumArtUrl ?? video.thumbnails.highResUrl;
          if (trackDuration == null) {
            finalDuration = _formatDuration(video.duration);
          }
        } catch (e) {}
      }

      final safeTitle = _sanitizeFilename(finalTitle);
      onProgress?.call('Fetching lyrics...', 0.1);
      final lyrics = await _lyricsService.fetchLyrics(
        finalArtist,
        finalTitle,
        youtubeId: videoId,
      );
      final syncedLyrics = lyrics['synced'];
      final plainLyrics = lyrics['plain'];

      final appDir = await getApplicationDocumentsDirectory();
      final musicDir = Directory(p.join(appDir.path, 'music'));
      if (!await musicDir.exists()) await musicDir.create(recursive: true);

      final finalPath = p.join(musicDir.path, '$safeTitle [$videoId].m4a');

      // --- WORKER MANAGEMENT ---
      HttpServer? progressServer;
      try {
        progressServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        final progressPort = progressServer.port;

        final currentDownloadCompleter = Completer<void>();
        final videoIdStr = videoId;
        _workerService.registerTaskCompleter(
          videoIdStr,
          currentDownloadCompleter,
        );

        progressServer.listen((HttpRequest request) async {
          if (request.uri.path == '/progress') {
            final content = await utf8.decoder.bind(request).join();
            try {
              final data = jsonDecode(content);
              final targetVideoId = data['videoId'] as String?;

              if (targetVideoId == videoIdStr) {
                final progress = (data['progress'] as num?)?.toDouble() ?? 0.0;
                final status = data['status'] as String?;

                if (status == 'done') {
                  onProgress?.call('Download complete!', 0.96);
                  if (!currentDownloadCompleter.isCompleted) {
                    currentDownloadCompleter.complete();
                  }
                } else if (status == 'error') {
                  final errorMsg =
                      data['error']?.toString() ??
                      data['message']?.toString() ??
                      'Unknown download error';
                  if (!currentDownloadCompleter.isCompleted) {
                    currentDownloadCompleter.completeError(Exception(errorMsg));
                  }
                } else if (status == 'processing') {
                  onProgress?.call('Finalizing file...', 0.95);
                } else {
                  onProgress?.call(
                    'Downloading: ${(progress * 100).toInt()}%',
                    0.15 + (progress * 0.8),
                  );
                }
              }
            } catch (e) {}
            request.response.statusCode = HttpStatus.ok;
            await request.response.close();
          }
        });

        await _workerService.initWorker();

        if (!_workerService.isReady) {
          throw Exception('Python Worker is not ready. Cannot download.');
        }

        onProgress?.call('Starting download...', 0.15);
        final response =
            await Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
              ),
            ).post(
              'http://127.0.0.1:${_workerService.workerPort}/download',
              data: {
                "url": url,
                "output_path": finalPath,
                "port": progressPort,
                "video_id": videoIdStr,
              },
            );

        if (response.statusCode != 200) {
          throw Exception("Failed to communicate with Python Worker");
        }

        await currentDownloadCompleter.future.timeout(
          const Duration(minutes: 15),
        );

        if (_workerService.getTaskError(videoIdStr) != null) {
          final err = _workerService.getTaskError(videoIdStr);
          _workerService.clearTaskError(videoIdStr);
          throw Exception(err);
        }

        onProgress?.call('Finished downloading!', 0.96);

        onProgress?.call('Optimizing audio...', 0.98);
        final tempPath = '$finalPath.tmp';
        final file = File(finalPath);
        if (await file.exists()) {
          await file.rename(tempPath);

          final session = await FFmpegKit.execute(
            '-i "$tempPath" -c copy -y "$finalPath"',
          );
          final returnCode = await session.getReturnCode();

          if (ReturnCode.isSuccess(returnCode)) {
            File(tempPath).delete().catchError((_) => File(tempPath));
          } else {
            await File(tempPath).rename(finalPath);
          }
        }

        onProgress?.call('Finished!', 1.0);
        return _createTrackModel(
          videoIdStr,
          finalTitle,
          finalArtist,
          finalAlbum,
          finalThumbnail,
          finalDuration,
          url,
          finalPath,
          syncedLyrics,
          plainLyrics,
        );
      } finally {
        await progressServer?.close();
        _workerService.removeTaskCompleter(videoId);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> getStreamUrl(
    String videoId, {
    bool forceWorker = false,
  }) async {
    const String separator =
        "==================================================";
    dev.log(separator, name: "YoutubeDownloadService");
    dev.log(
      "🎵 STARTING STREAM URL ACQUISITION",
      name: "YoutubeDownloadService",
    );
    dev.log("📹 Video ID: $videoId", name: "YoutubeDownloadService");

    String? videoTitle;
    try {
      // Pre-fetch video info for better logging (Title)
      final video = await _yt.videos.get(videoId);
      videoTitle = video.title;
      dev.log("📝 Title: $videoTitle", name: "YoutubeDownloadService");
    } catch (e) {
      dev.log(
        "📝 Title: (Metadata fetch failed)",
        name: "YoutubeDownloadService",
      );
    }

    dev.log("⚙️ Force Worker: $forceWorker", name: "YoutubeDownloadService");
    dev.log(separator, name: "YoutubeDownloadService");

    try {
      if (!forceWorker) {
        // 1. Try youtube_explode_dart FIRST for instant playback (Zero delay)
        dev.log(
          "⚡ Strategy 1: YouTubeExplode (Instant)",
          name: "YoutubeDownloadService",
        );
        try {
          // Set a strict timeout for Strategy 1 to avoid long delays
          final manifest = await _yt.videos.streamsClient
              .getManifest(videoId)
              .timeout(const Duration(seconds: 3));

          // Prefer m4a streams for better iOS compatibility
          final m4aStreams = manifest.audioOnly.where(
            (s) => s.container == StreamContainer.mp4,
          );

          final streamInfo = m4aStreams.isNotEmpty
              ? m4aStreams.withHighestBitrate()
              : manifest.audioOnly.withHighestBitrate();

          final url = streamInfo.url.toString();
          dev.log(
            "✅ SUCCESS: YouTubeExplode retrieved URL",
            name: "YoutubeDownloadService",
          );
          dev.log(
            "📦 Container: ${streamInfo.container}",
            name: "YoutubeDownloadService",
          );
          dev.log(
            "🎧 Bitrate: ${streamInfo.bitrate}",
            name: "YoutubeDownloadService",
          );
          dev.log("🔗 URL: $url", name: "YoutubeDownloadService");
          dev.log(separator, name: "YoutubeDownloadService");
          return url;
        } catch (e) {
          dev.log(
            "⚠️ YouTubeExplode Failed: $e",
            name: "YoutubeDownloadService",
          );
          dev.log(
            "🔄 Falling back to Strategy 2...",
            name: "YoutubeDownloadService",
          );
        }
      } else {
        dev.log(
          "🛠️ Strategy: Forced Python Worker",
          name: "YoutubeDownloadService",
        );
      }

      // 2. Fallback to Python Worker (yt-dlp) if YouTubeExplode fails or throttles
      dev.log(
        "🐍 Strategy 2: Python Worker (yt-dlp)",
        name: "YoutubeDownloadService",
      );

      await _workerService.initWorker().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          dev.log(
            "❌ ERROR: Python Worker initialization timed out",
            name: "YoutubeDownloadService",
          );
          throw TimeoutException("Worker init timeout");
        },
      );

      if (_workerService.isReady && _workerService.workerPort != null) {
        try {
          final response = await Dio()
              .post(
                'http://127.0.0.1:${_workerService.workerPort}/get_url',
                data: {"video_id": videoId},
              )
              .timeout(const Duration(seconds: 30));

          if (response.statusCode == 200 && response.data['url'] != null) {
            final url = response.data['url'];
            dev.log(
              "✅ SUCCESS: Python Worker retrieved URL",
              name: "YoutubeDownloadService",
            );
            dev.log("🔗 URL: $url", name: "YoutubeDownloadService");
            dev.log(separator, name: "YoutubeDownloadService");
            return url;
          } else {
            dev.log(
              "❌ ERROR: Worker returned invalid status: ${response.statusCode}",
              name: "YoutubeDownloadService",
            );
          }
        } catch (e) {
          dev.log(
            "❌ ERROR: Worker request failed: $e",
            name: "YoutubeDownloadService",
          );
        }
      } else {
        dev.log(
          "❌ ERROR: Python Worker is NOT ready",
          name: "YoutubeDownloadService",
        );
      }

      dev.log(
        "🚫 FAILED: All strategies exhausted. No URL found.",
        name: "YoutubeDownloadService",
      );
      dev.log(separator, name: "YoutubeDownloadService");
      return null;
    } catch (e) {
      dev.log("🔥 FATAL ERROR: $e", name: "YoutubeDownloadService");
      dev.log(separator, name: "YoutubeDownloadService");
      return null;
    }
  }

  TrackModel _createTrackModel(
    String id,
    String title,
    String author,
    String album,
    String thumb,
    String duration,
    String url,
    String path,
    String? syncedLyrics,
    String? plainLyrics,
  ) {
    return TrackModel(
      idField: id,
      titleField: title,
      artistField: author,
      albumField: album,
      albumArtUrlField: thumb,
      durationField: duration,
      audioUrlField: url,
      localPathField: path,
      syncedLyricsField: syncedLyrics,
      plainLyricsField: plainLyrics,
    );
  }

  String _sanitizeFilename(String name) {
    String sanitized = name.replaceAll(_illegalChars, '_');
    sanitized = sanitized.replaceAll(_controlChars, '');
    sanitized = sanitized.trim();
    if (sanitized.length > 200) {
      sanitized = sanitized.substring(0, 200);
    }
    return sanitized.isEmpty ? 'download' : sanitized;
  }

  String _formatDuration(Duration? duration) {
    if (duration == null || duration == Duration.zero) return "0:00";
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return "$minutes:${seconds.toString().padLeft(2, '0')}";
  }
}
