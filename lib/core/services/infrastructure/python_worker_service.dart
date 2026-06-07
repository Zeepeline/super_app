import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:serious_python/serious_python.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_app/features/book_search/domain/entities/book_search_result.dart';

class PythonWorkerService {
  final SharedPreferences _prefs;
  final Dio _dio = Dio();

  // Global Worker State
  bool _isWorkerStarted = false;
  bool _isInitializing = false;
  int? _workerPort;
  bool _wasRunCalledInThisProcess = false;

  final Map<String, Completer<void>> _activeDownloadCompleters = {};
  final Map<String, String?> _downloadErrors = {};
  Completer<void>? _initCompleter;

  PythonWorkerService(this._prefs);

  int? get workerPort => _workerPort;
  bool get isReady => _isWorkerStarted && _workerPort != null;

  /// Register a completer for a specific task (e.g. YouTube download)
  void registerTaskCompleter(String taskId, Completer<void> completer) {
    _activeDownloadCompleters[taskId] = completer;
  }

  void removeTaskCompleter(String taskId) {
    _activeDownloadCompleters.remove(taskId);
  }

  String? getTaskError(String taskId) => _downloadErrors[taskId];
  void clearTaskError(String taskId) => _downloadErrors.remove(taskId);

  /// Ensures the Python worker is running and ready
  Future<void> initWorker() async {
    if (_isWorkerStarted && _workerPort != null) return;

    if (_initCompleter != null) {
      return _initCompleter!.future;
    }

    _initCompleter = Completer<void>();
    _isInitializing = true;
    try {
      dev.log("Initializing Python worker...", name: "PythonWorker");
      final savedPort = _prefs.getInt('python_worker_port');
      final savedPid = _prefs.getInt('python_worker_pid');
      final currentPid = pid;

      if (savedPort != null && savedPid == currentPid) {
        dev.log(
          "Found existing worker on port $savedPort for PID $currentPid",
          name: "PythonWorker",
        );
        if (await _pingWorker(savedPort)) {
          _workerPort = savedPort;
          _isWorkerStarted = true;
          await _setupNewProgressServer();
          dev.log(
            "Existing worker is alive and reconnected.",
            name: "PythonWorker",
          );
          _initCompleter!.complete();
          return;
        }
        dev.log(
          "Existing worker at $savedPort is not responding.",
          name: "PythonWorker",
        );
      }

      if (_wasRunCalledInThisProcess) {
        dev.log(
          "SeriousPython.run was already called. Re-checking status...",
          name: "PythonWorker",
        );

        // Check if the late handshake already set the port
        if (_workerPort != null && await _pingWorker(_workerPort!)) {
          _isWorkerStarted = true;
          await _prefs.setInt('python_worker_port', _workerPort!);
          await _setupNewProgressServer();
          dev.log(
            "Reconnected to late-started worker on port $_workerPort",
            name: "PythonWorker",
          );
        } else if (savedPort != null && await _pingWorker(savedPort)) {
          _workerPort = savedPort;
          _isWorkerStarted = true;
          await _setupNewProgressServer();
        }
        _initCompleter!.complete();
        return;
      }

      dev.log(
        "Starting a fresh Python worker process...",
        name: "PythonWorker",
      );
      await _prefs.setInt('python_worker_pid', pid);
      await _startFreshWorker();

      if (_workerPort != null) {
        dev.log(
          "New worker started on port $_workerPort",
          name: "PythonWorker",
        );
        await _prefs.setInt('python_worker_port', _workerPort!);
      }
      _initCompleter!.complete();
    } catch (e) {
      dev.log(
        "PythonWorkerService: Initialization error: $e",
        name: "PythonWorker",
        error: e,
      );
      if (!_initCompleter!.isCompleted) {
        _initCompleter!.completeError(e);
      }
    } finally {
      _isInitializing = false;
      // Always reset so future calls can re-check worker state
      _initCompleter = null;
    }
  }

  Future<bool> _pingWorker(int port) async {
    try {
      final response = await _dio.get(
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
    try {
      final progressServer = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        0,
      );
      final progressPort = progressServer.port;
      dev.log(
        "New progress signal server listening on port $progressPort",
        name: "PythonWorker",
      );

      progressServer.listen((HttpRequest request) async {
        if (request.uri.path == '/progress') {
          final content = await utf8.decoder.bind(request).join();
          _handleProgressData(content);
          request.response.statusCode = HttpStatus.ok;
          await request.response.close();
        }
      });

      await _dio.post(
        'http://127.0.0.1:$_workerPort/update_dart_port',
        data: {"port": progressPort},
      );
    } catch (e) {
      dev.log(
        "Error updating progress server port in Python: $e",
        name: "PythonWorker",
        error: e,
      );
    }
  }

  Future<void> downloadBook(BookSearchResult book) async {
    if (!isReady) await initWorker();

    if (_workerPort == null) {
      throw Exception(
        'Python Worker is not ready (port is null). Cannot download.',
      );
    }

    final taskId = book.id;
    final completer = Completer<void>();
    registerTaskCompleter(taskId, completer);

    try {
      final docDir = await getApplicationDocumentsDirectory();
      final savePath = '${docDir.path}/SoundWave/Books';

      dev.log(
        "Requesting download for book: ${book.title}",
        name: "PythonWorker",
      );
      dev.log("Download URL: ${book.mirror}", name: "PythonWorker");
      await _dio.post(
        'http://127.0.0.1:$_workerPort/books/download',
        data: {
          "id": book.id,
          "url": book.mirror,
          "title": book.title,
          "author": book.author,
          "format": book.format,
          "source": book.source,
          "save_path": savePath,
        },
      );

      // Wait for the 'done' or 'error' signal from Python
      await completer.future;
      dev.log(
        "Download task finished for: ${book.title}",
        name: "PythonWorker",
      );
    } catch (e) {
      dev.log(
        "Download failed for ${book.title}: $e",
        name: "PythonWorker",
        error: e,
      );
      _downloadErrors[taskId] = e.toString();
      rethrow;
    } finally {
      removeTaskCompleter(taskId);
    }
  }

  /// Melakukan permintaan POST sinkron ke worker
  Future<Map<String, dynamic>> postSync(
    String path,
    Map<String, dynamic> data,
  ) async {
    if (!isReady) await initWorker();

    if (_workerPort == null) {
      throw Exception('Python Worker is not ready.');
    }

    try {
      final response = await _dio.post(
        'http://127.0.0.1:$_workerPort$path',
        data: data,
        options: Options(
          receiveTimeout: const Duration(seconds: 30),
          connectTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Worker returned status: ${response.statusCode}');
      }
    } catch (e) {
      dev.log("Error in postSync ($path): $e", name: "PythonWorker", error: e);
      rethrow;
    }
  }

  Future<void> _startFreshWorker() async {
    HttpServer? progressServer;
    bool timedOut = false;
    try {
      progressServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final progressPort = progressServer.port;
      final completer = Completer<void>();
      dev.log(
        "Temporary handshake server listening on port $progressPort",
        name: "PythonWorker",
      );

      progressServer.listen((HttpRequest request) async {
        if (request.uri.path == '/progress') {
          final content = await utf8.decoder.bind(request).join();
          try {
            final data = jsonDecode(content);
            if (data['status'] == 'worker_ready') {
              _workerPort = (data['port'] as num).toInt();
              _isWorkerStarted = true;
              dev.log(
                "Received worker port from Python: $_workerPort",
                name: "PythonWorker",
              );
              if (!completer.isCompleted) completer.complete();

              // If this arrived after timeout, set up the progress server now
              if (timedOut) {
                dev.log(
                  "Late handshake accepted! Worker is alive on port $_workerPort",
                  name: "PythonWorker",
                );
                await _prefs.setInt('python_worker_port', _workerPort!);
                await _setupNewProgressServer();
              }
            } else {
              _handleProgressData(content);
            }
          } catch (e) {
            dev.log(
              "Error parsing handshake data: $e",
              name: "PythonWorker",
              error: e,
            );
          }
          request.response.statusCode = HttpStatus.ok;
          await request.response.close();
        }
      });

      const appPath = "app/app.zip";
      dev.log("Calling SeriousPython.run for $appPath", name: "PythonWorker");
      _wasRunCalledInThisProcess = true;

      SeriousPython.run(
        appPath,
        appFileName: "main.py",
        environmentVariables: {"DART_PORT": progressPort.toString()},
      );

      // iOS can be very slow to unpack and start Python (>2 min observed).
      // Give it 5 minutes to be safe.
      await completer.future.timeout(const Duration(minutes: 5));
      _isWorkerStarted = true;
    } on TimeoutException {
      timedOut = true;
      dev.log(
        "Python Worker did not respond within 5 minutes. "
        "It may still start later — keeping handshake server open.",
        name: "PythonWorker",
      );
      // Don't clear _workerPort here — the listener may still receive it.
    } finally {
      // Keep the handshake server alive longer in case Python is just slow.
      // If it already started, close sooner.
      final closeDelay = timedOut
          ? const Duration(minutes: 2)
          : const Duration(seconds: 5);
      Future.delayed(closeDelay, () {
        dev.log("Closing temporary handshake server", name: "PythonWorker");
        progressServer?.close();
      });
    }
  }

  void _handleProgressData(String content) {
    try {
      final data = jsonDecode(content);
      final status = data['status'] as String?;

      // Handle direct log messages from Python
      if (status == 'log') {
        final message = data['message'] as String?;
        if (message != null) {
          dev.log(message, name: "PythonWorker");
        }
        return;
      }

      final taskId = data['videoId'] as String?; // Could be bookId or videoId

      if (taskId != null && _activeDownloadCompleters.containsKey(taskId)) {
        if (status == 'done' || status == 'error') {
          if (status == 'error') {
            final errorMsg =
                data['error']?.toString() ??
                data['message']?.toString() ??
                'Unknown error';
            dev.log(
              "Download signal error for $taskId: $errorMsg",
              name: "PythonWorker",
            );
            _downloadErrors[taskId] = errorMsg;
          } else {
            dev.log(
              "Download signal complete for $taskId",
              name: "PythonWorker",
            );
          }
          if (!_activeDownloadCompleters[taskId]!.isCompleted) {
            _activeDownloadCompleters[taskId]!.complete();
          }
        }
      }
    } catch (e) {
      dev.log(
        "Error handling progress data: $e",
        name: "PythonWorker",
        error: e,
      );
    }
  }
}
