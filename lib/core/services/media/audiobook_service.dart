import 'dart:developer' as dev;

import 'package:dio/dio.dart';
import 'package:super_app/core/services/infrastructure/python_worker_service.dart';
import 'package:super_app/core/services/media/audio_handler.dart';
import 'package:super_app/features/music_player/domain/entities/track_entity.dart';

class AudiobookService {
  final PythonWorkerService _workerService;
  final AudioHandler _audioHandler;
  final Dio _dio = Dio();

  AudiobookService(this._workerService, this._audioHandler);

  Future<Map<String, dynamic>> getBookInfo(String pdfPath) async {
    if (!_workerService.isReady) await _workerService.initWorker();

    try {
      final response = await _dio.post(
        'http://127.0.0.1:${_workerService.workerPort}/audiobook/info',
        data: {"path": pdfPath},
      );
      return response.data;
    } catch (e) {
      dev.log("AudiobookService: Error fetching book info: $e");
      return {"error": e.toString()};
    }
  }

  Future<void> readPage(
    String pdfPath,
    int pageNum, {
    String? title,
    String? author,
  }) async {
    if (!_workerService.isReady) await _workerService.initWorker();

    try {
      dev.log("AudiobookService: Requesting audio for page $pageNum");
      final response = await _dio.post(
        'http://127.0.0.1:${_workerService.workerPort}/audiobook/read_page',
        data: {
          "path": pdfPath,
          "page": pageNum,
          "voice": "id-ID-ArdiNeural", // Default voice
        },
      );

      if (response.statusCode == 200) {
        final audioPath = response.data['audio_path'];

        // Convert this "page" into a virtual track for our AudioHandler
        final track = TrackEntity(
          id: "audiobook_${pdfPath.hashCode}_$pageNum",
          title: "${title ?? 'Audiobook'} - Hal ${pageNum + 1}",
          artist: author ?? "AI Reader",
          album: title ?? "Audiobook Collection",
          albumArtUrl:
              "https://cdn-icons-png.flaticon.com/512/2840/2840131.png", // Placeholder audiobook icon
          audioUrl: "",
          localPath: audioPath,
          duration: Duration.zero, // AudioHandler will resolve this
        );

        // Play the generated audio
        await _audioHandler.playTrack(track);
      }
    } catch (e) {
      dev.log("AudiobookService: Error reading page: $e");
      rethrow;
    }
  }
}
