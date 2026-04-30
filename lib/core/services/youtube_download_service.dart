import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:serious_python/serious_python.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../../features/home/data/models/track_model.dart';
import './lyrics_service.dart';

class YoutubeDownloadService {
  final YoutubeExplode _yt = YoutubeExplode();
  final LyricsService _lyricsService;

  // Persistent Worker State
  static bool _isWorkerStarted = false;
  static int? _workerPort;
  static final Map<String, Completer<void>> _activeDownloadCompleters = {};
  static final Map<String, String?> _downloadErrors = {};

  YoutubeDownloadService(this._lyricsService);

  void dispose() {
    _yt.close();
  }

  Future<TrackModel?> downloadAndConvert({
    required String url,
    Function(String stage, double progress)? onProgress,
  }) async {
    try {
      final videoId = VideoId.parseVideoId(url);
      if (videoId == null) throw Exception('URL YouTube tidak valid');

      onProgress?.call('Fetching metadata...', 0.05);

      Video? video;
      try {
        video = await _yt.videos
            .get(videoId)
            .timeout(const Duration(seconds: 10));
      } catch (e) {
        print(
          "YoutubeDownloadService: Metadata fetch failed, using generic: $e",
        );
      }

      final title = video?.title ?? 'YouTube Audio';
      final author = video?.author ?? 'Unknown Artist';
      final thumbnail = video?.thumbnails.highResUrl ?? '';
      final duration = video?.duration != null
          ? video!.duration.toString()
          : '0:00:00';

      onProgress?.call('Fetching lyrics...', 0.1);
      final lyrics = await _lyricsService.fetchLyrics(
        author,
        title,
        youtubeId: videoId,
      );
      final syncedLyrics = lyrics['synced'];
      final plainLyrics = lyrics['plain'];

      final appDir = await getApplicationDocumentsDirectory();
      final musicDir = Directory(p.join(appDir.path, 'music'));
      if (!await musicDir.exists()) await musicDir.create(recursive: true);

      final safeTitle = _sanitizeFilename(title);
      final finalPath = p.join(musicDir.path, '$safeTitle [$videoId].m4a');

      // --- WORKER MANAGEMENT ---
      HttpServer? progressServer;
      try {
        progressServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        final progressPort = progressServer.port;

        final currentDownloadCompleter = Completer<void>();
        final videoIdStr = videoId;
        _activeDownloadCompleters[videoIdStr] = currentDownloadCompleter;

        progressServer.listen((HttpRequest request) async {
          if (request.uri.path == '/progress') {
            final content = await utf8.decoder.bind(request).join();
            try {
              final data = jsonDecode(content);
              final status = data['status'] as String?;
              final targetVideoId = data['videoId'] as String?;

              if (status == 'worker_ready') {
                _workerPort = (data['port'] as num).toInt();
              } else if (targetVideoId == videoIdStr) {
                final progress = (data['progress'] as num?)?.toDouble() ?? 0.0;

                if (status == 'error') {
                  _downloadErrors[videoIdStr] =
                      data['error']?.toString() ?? 'Unknown error';
                  if (!currentDownloadCompleter.isCompleted)
                    currentDownloadCompleter.complete();
                } else if (status == 'done') {
                  if (!currentDownloadCompleter.isCompleted)
                    currentDownloadCompleter.complete();
                } else if (status == 'processing') {
                  onProgress?.call('Finalizing file...', 0.95);
                } else {
                  onProgress?.call(
                    'Downloading: ${(progress * 100).toInt()}%',
                    0.15 + (progress * 0.8),
                  );
                }
              }
            } catch (e) {
              print("YoutubeDownloadService: JSON error: $e");
            }
            request.response.statusCode = HttpStatus.ok;
            await request.response.close();
          }
        });

        if (!_isWorkerStarted) {
          onProgress?.call('Initializing Python Worker...', 0.12);
          print(
            "YoutubeDownloadService: Launching Python Worker via SeriousPython...",
          );

          SeriousPython.run(
            "app/app.zip",
            appFileName: "main.py",
            environmentVariables: {"DART_PORT": progressPort.toString()},
          );

          int wait = 0;
          while (_workerPort == null && wait < 60) {
            await Future.delayed(const Duration(milliseconds: 500));
            wait++;
          }
          if (_workerPort == null)
            throw Exception("Python Worker failed to start.");
          _isWorkerStarted = true;
          print("YoutubeDownloadService: Worker is ready on port $_workerPort");
        }

        onProgress?.call('Starting download...', 0.15);
        final response = await Dio().post(
          'http://127.0.0.1:$_workerPort/download',
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

        if (_downloadErrors[videoIdStr] != null) {
          final err = _downloadErrors[videoIdStr];
          _downloadErrors.remove(videoIdStr);
          throw Exception(err);
        }

        onProgress?.call('Finished!', 1.0);
        return _createTrackModel(
          videoIdStr,
          title,
          author,
          thumbnail,
          duration,
          url,
          finalPath,
          syncedLyrics,
          plainLyrics,
        );
      } finally {
        await progressServer?.close();
        _activeDownloadCompleters.remove(videoId);
      }
    } catch (e) {
      print("YoutubeDownloadService Error: $e");
      rethrow;
    }
  }

  TrackModel _createTrackModel(
    String id,
    String title,
    String author,
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
      albumArtUrlField: thumb,
      durationField: duration,
      audioUrlField: url,
      localPathField: path,
      syncedLyricsField: syncedLyrics,
      plainLyricsField: plainLyrics,
    );
  }

  String _sanitizeFilename(String name) {
    // Character that are illegal in Windows/macOS/Linux filenames
    final illegalChars = RegExp(r'[<>:"/\\|?*]');
    // Replace with underscores
    String sanitized = name.replaceAll(illegalChars, '_');
    // Remove control characters
    sanitized = sanitized.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');
    // Trim and handle extremely long names (max 200 chars to be safe)
    sanitized = sanitized.trim();
    if (sanitized.length > 200) {
      sanitized = sanitized.substring(0, 200);
    }
    return sanitized.isEmpty ? 'download' : sanitized;
  }

  // void dispose() {
  //   _yt.close();
  // }
}
