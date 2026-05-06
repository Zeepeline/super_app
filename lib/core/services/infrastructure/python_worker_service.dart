import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:dio/dio.dart';
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
        if (savedPort != null && await _pingWorker(savedPort)) {
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
      _initCompleter = null;
    } finally {
      _isInitializing = false;
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

    final taskId = book.id;
    final completer = Completer<void>();
    registerTaskCompleter(taskId, completer);

    try {
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

  Future<void> _startFreshWorker() async {
    HttpServer? progressServer;
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
          final data = jsonDecode(content);
          if (data['status'] == 'worker_ready') {
            _workerPort = (data['port'] as num).toInt();
            dev.log(
              "Received worker port from Python: $_workerPort",
              name: "PythonWorker",
            );
            if (!completer.isCompleted) completer.complete();
          } else {
            _handleProgressData(content);
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

      await completer.future.timeout(const Duration(seconds: 120));
      _isWorkerStarted = true;
    } finally {
      Future.delayed(const Duration(seconds: 5), () {
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
            dev.log(
              "Download signal error for $taskId: ${data['error']}",
              name: "PythonWorker",
            );
            _downloadErrors[taskId] =
                data['error']?.toString() ?? 'Unknown error';
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
