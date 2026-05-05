import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:super_app/core/services/media/lyrics_service.dart';
import 'package:super_app/core/services/infrastructure/python_worker_service.dart';
import 'package:super_app/features/home/data/models/track_model.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YoutubeDownloadService {
  final YoutubeExplode _yt = YoutubeExplode();
  final LyricsService _lyricsService;
  final PythonWorkerService _workerService;

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

                if (status == 'processing') {
                  onProgress?.call('Finalizing file...', 0.95);
                } else if (status != 'done' && status != 'error') {
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

        onProgress?.call('Starting download...', 0.15);
        final response = await Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        )).post(
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

  Future<String?> getStreamUrl(String videoId) async {
    try {
      // 1. Try Python Worker first (Usually more stable for long-term URLs)
      await _workerService.initWorker().timeout(
        const Duration(seconds: 15),
        onTimeout: () => dev.log("Worker init timeout, falling back to YouTubeExplode", name: "YoutubeDownloadService"),
      );

      if (_workerService.isReady) {
        try {
          final response = await Dio()
              .post(
                'http://127.0.0.1:${_workerService.workerPort}/get_url',
                data: {"video_id": videoId},
              )
              .timeout(const Duration(seconds: 10));

          if (response.statusCode == 200 && response.data['url'] != null) {
            return response.data['url'];
          }
        } catch (e) {
          dev.log("Worker get_url failed: $e, trying fallback...", name: "YoutubeDownloadService");
        }
      }

      // 2. Fallback to youtube_explode_dart directly if worker fails
      dev.log("Using YouTubeExplode fallback for $videoId", name: "YoutubeDownloadService");
      final manifest = await _yt.videos.streamsClient.getManifest(videoId);
      final streamInfo = manifest.audioOnly.withHighestBitrate();
      return streamInfo.url.toString();
    } catch (e) {
      dev.log("Final error getting stream URL: $e", name: "YoutubeDownloadService");
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
    final illegalChars = RegExp(r'[<>:"/\\|?*]');
    String sanitized = name.replaceAll(illegalChars, '_');
    sanitized = sanitized.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');
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
