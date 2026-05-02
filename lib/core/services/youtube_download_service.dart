import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:serious_python/serious_python.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../../features/home/data/models/track_model.dart';
import './lyrics_service.dart';
import './secure_storage_service.dart';

class YoutubeDownloadService {
  final YoutubeExplode _yt = YoutubeExplode();
  final LyricsService _lyricsService;
  final SecureStorageService _secureStorage;

  // Persistent Worker State
  static bool _isWorkerStarted = false;
  static bool _isInitializing = false; // ignore: unused_field
  static int? _workerPort;
  static bool _wasRunCalledInThisProcess = false;
  static final Map<String, Completer<void>> _activeDownloadCompleters = {};
  static final Map<String, String?> _downloadErrors = {};

  YoutubeDownloadService(this._lyricsService, this._secureStorage);

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
        } catch (e) {
          // ignore: empty_catches
        }
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
                  if (!currentDownloadCompleter.isCompleted) {
                    currentDownloadCompleter.complete();
                  }
                } else if (status == 'done') {
                  if (!currentDownloadCompleter.isCompleted) {
                    currentDownloadCompleter.complete();
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

        await initWorker();

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

        onProgress?.call('Finished downloading!', 0.96);

        // --- FFmpeg FIX ---
        // Sometimes YouTube m4a files have wrong headers/duration.
        // We use ffmpeg-kit (which is already in pubspec) to re-mux it.
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
        _activeDownloadCompleters.remove(videoId);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get direct stream URL via yt-dlp (Python Worker)
  Future<String?> getStreamUrl(String videoId) async {
    try {
      // 1. Try to initialize worker.
      // On first run (extraction), this can take 15-20s.
      // We wait up to 45s to be safe, but it returns immediately if already ready.
      await initWorker().timeout(const Duration(seconds: 45), onTimeout: () {});

      // 2. Plan A: Try Python Worker (yt-dlp) if available
      if (_workerPort != null) {
        try {
          final response = await Dio()
              .post(
                'http://127.0.0.1:$_workerPort/get_url',
                data: {"video_id": videoId},
              )
              .timeout(const Duration(seconds: 15));

          if (response.statusCode == 200 && response.data['url'] != null) {
            return response.data['url'];
          } else {
            return null;
          }
        } catch (e) {
          return null;
        }
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  static Completer<void>? _initCompleter;

  /// Ensures the Python worker is running and ready
  Future<void> initWorker() async {
    if (_isWorkerStarted && _workerPort != null) return;

    if (_initCompleter != null) {
      return _initCompleter!.future;
    }

    _initCompleter = Completer<void>();
    _isInitializing = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPort = prefs.getInt('python_worker_port');
      final savedPid = prefs.getInt('python_worker_pid');
      final currentPid = pid;

      if (savedPort != null && savedPid == currentPid) {
        if (await _pingWorker(savedPort)) {
          _workerPort = savedPort;
          _isWorkerStarted = true;
          await _setupNewProgressServer();
          if (!_initCompleter!.isCompleted) _initCompleter!.complete();
          return;
        }
      }

      // 2. Start fresh worker
      if (_wasRunCalledInThisProcess) {
        if (savedPort != null && await _pingWorker(savedPort)) {
          _workerPort = savedPort;
          _isWorkerStarted = true;
          await _setupNewProgressServer();
          _initCompleter!.complete();
          return;
        }
        _initCompleter!.complete();
        return;
      }

      // Save PID *before* run to handle Hot Restart during initialization
      await prefs.setInt('python_worker_pid', pid);

      await _startFreshWorker();

      if (_workerPort != null) {
        await prefs.setInt('python_worker_port', _workerPort!);
      }

      _initCompleter!.complete();
    } catch (e) {
      if (!_initCompleter!.isCompleted) _initCompleter!.completeError(e);
      _initCompleter = null;
    } finally {
      _isInitializing = false;
    }
  }

  Future<bool> _pingWorker(int port) async {
    try {
      final response = await Dio().get(
        'http://127.0.0.1:$port/status',
        options: Options(
          receiveTimeout: const Duration(seconds: 2),
          connectTimeout: const Duration(seconds: 2),
        ),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<void> _setupNewProgressServer() async {
    HttpServer? progressServer;
    try {
      progressServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final progressPort = progressServer.port;

      progressServer.listen((HttpRequest request) async {
        if (request.uri.path == '/progress') {
          final content = await utf8.decoder.bind(request).join();
          try {
            final data = jsonDecode(content);
            final videoId = data['videoId'] as String?;
            final status = data['status'] as String?;

            if (videoId != null &&
                _activeDownloadCompleters.containsKey(videoId)) {
              // Handle progress as before
              if (status == 'done' || status == 'error') {
                if (!_activeDownloadCompleters[videoId]!.isCompleted) {
                  _activeDownloadCompleters[videoId]!.complete();
                }
              }
              // Progress updates are handled by the caller who has the onProgress callback
              // For simplicity, we keep it global or rely on the fact that
              // only one download happens at a time or they are keyed by videoId.
            }
          } catch (e) {}
          request.response.statusCode = HttpStatus.ok;
          await request.response.close();
        }
      });

      // Tell the existing Python worker to update its DART_PORT
      await Dio().post(
        'http://127.0.0.1:$_workerPort/update_dart_port',
        data: {"port": progressPort},
      );

      // Keep server alive
      // Note: In a real app, you might want to manage this lifecycle better
    } catch (e) {}
  }

  Future<void> _startFreshWorker() async {
    HttpServer? progressServer;
    try {
      progressServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final progressPort = progressServer.port;

      final completer = Completer<void>();

      progressServer.listen((HttpRequest request) async {
        if (request.uri.path == '/progress') {
          final content = await utf8.decoder.bind(request).join();
          try {
            final data = jsonDecode(content);
            if (data['status'] == 'worker_ready') {
              _workerPort = (data['port'] as num).toInt();
              if (!completer.isCompleted) completer.complete();
            }
          } catch (e) {}
          request.response.statusCode = HttpStatus.ok;
          await request.response.close();
        }
      });

      const appPath = "app/app.zip";
      await Future.delayed(const Duration(seconds: 2));

      _wasRunCalledInThisProcess = true;

      // Fetch the API key from secure storage
      final geminiKey = await _secureStorage.getGeminiApiKey();

      // For iOS, extraction and re-initialization are sensitive.
      SeriousPython.run(
        appPath,
        appFileName: "main.py",
        environmentVariables: {
          "DART_PORT": progressPort.toString(),
          "GEMINI_API_KEY": geminiKey ?? "",
        },
      );

      await completer.future.timeout(const Duration(seconds: 60));

      if (_workerPort == null) {
        throw Exception("Python Worker failed to start.");
      }

      // Persist the port for future sessions (Hot Restarts)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('python_worker_port', _workerPort!);

      _isWorkerStarted = true;
    } finally {
      // We keep the server alive briefly to handle any late messages
      Future.delayed(const Duration(seconds: 5), () {
        progressServer?.close();
      });
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

  String _formatDuration(Duration? duration) {
    if (duration == null || duration == Duration.zero) return "0:00";
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return "$minutes:${seconds.toString().padLeft(2, '0')}";
  }
}
