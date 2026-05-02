import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/home/data/datasources/home_local_data_source.dart';

/// RagService — Berkomunikasi dengan Python RAG backend (Flask + ChromaDB).
///
/// Bertanggung jawab untuk:
/// 1. Mengirim query ke /rag/chat untuk mendapatkan augmented prompt
/// 2. Mengindex lagu baru ke ChromaDB via /index/music
/// 3. Menyinkronisasi seluruh library via /index/batch
/// 4. Mengambil statistik dari /rag/stats
class RagService {
  final HomeLocalDataSource _localDataSource;
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 10),
  ));

  RagService(this._localDataSource);

  /// Mendapatkan port Python worker dari SharedPreferences
  Future<int?> _getWorkerPort() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('python_worker_port');
  }

  /// Base URL untuk Python worker
  Future<String?> _baseUrl() async {
    final port = await _getWorkerPort();
    if (port == null) return null;
    return 'http://127.0.0.1:$port';
  }

  // ========== RAG CHAT ==========

  /// Mendapatkan konteks lokal yang sudah di-augment dari Python RAG.
  /// Ini menggantikan simple keyword matching sebelumnya.
  Future<String?> getLocalContext(String query) async {
    try {
      final url = await _baseUrl();
      if (url == null) return null;

      final response = await _dio.post(
        '$url/rag/chat',
        data: {"query": query},
      );

      if (response.statusCode == 200 && response.data['status'] == 'ok') {
        return response.data['data']['context'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ========== INDEXING ==========

  /// Index satu lagu ke ChromaDB
  Future<bool> indexTrack({
    required String id,
    required String title,
    required String artist,
    String? album,
    String? genre,
  }) async {
    try {
      final url = await _baseUrl();
      if (url == null) return false;

      final response = await _dio.post(
        '$url/index/music',
        data: {
          "id": id,
          "title": title,
          "artist": artist,
          "album": album ?? '',
          "genre": genre ?? '',
        },
      );

      return response.statusCode == 200 &&
          response.data['status'] == 'ok';
    } catch (e) {
      return false;
    }
  }

  /// Sync semua lagu dari library lokal ke ChromaDB (bulk index)
  Future<Map<String, int>> syncAllTracks() async {
    try {
      final url = await _baseUrl();
      if (url == null) return {'success': 0, 'failed': 0};

      final tracks = await _localDataSource.getPopularTracks();
      if (tracks.isEmpty) return {'success': 0, 'failed': 0};

      final List<Map<String, dynamic>> batch = tracks.map((t) => {
        'source_type': 'music',
        'id': t.id,
        'title': t.title,
        'artist': t.artist,
        'album': t.album,
      }).toList();

      final response = await _dio.post(
        '$url/index/batch',
        data: batch,
        options: Options(receiveTimeout: const Duration(seconds: 60)),
      );

      if (response.statusCode == 200 && response.data['status'] == 'ok') {
        final data = response.data['data'];
        return {
          'success': data['success'] ?? 0,
          'failed': data['failed'] ?? 0,
        };
      }
      return {'success': 0, 'failed': 0};
    } catch (e) {
      return {'success': 0, 'failed': 0};
    }
  }

  // ========== STATS ==========

  /// Mengambil statistik dari ChromaDB
  Future<Map<String, dynamic>?> getStats() async {
    try {
      final url = await _baseUrl();
      if (url == null) return null;

      final response = await _dio.get('$url/rag/stats');
      if (response.statusCode == 200 && response.data['status'] == 'ok') {
        return response.data['data'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ========== SETUP ==========

  /// Download stopwords dari internet
  Future<bool> downloadStopwords() async {
    try {
      final url = await _baseUrl();
      if (url == null) return false;

      final response = await _dio.post('$url/setup/download_stopwords');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Cek status setup Python RAG
  Future<Map<String, dynamic>?> getSetupStatus() async {
    try {
      final url = await _baseUrl();
      if (url == null) return null;

      final response = await _dio.get('$url/setup/status');
      if (response.statusCode == 200) {
        return response.data['data'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
