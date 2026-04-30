import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YouTubeExplodeService {
  late YoutubeHttpClient _httpClient;
  late YoutubeExplode _yt;

  YouTubeExplodeService() {
    _initClient();
  }

  void _initClient() {
    _httpClient = YoutubeHttpClient();
    _yt = YoutubeExplode(httpClient: _httpClient);
  }

  /// Search for videos by query.
  Future<List<Video>> searchVideos(String query) async {
    try {
      final searchList = await _yt.search.search(
        query,
        filter: TypeFilters.video,
      );
      return searchList.toList();
    } catch (e) {
      debugPrint('YouTube Search Error: $e');
      throw Exception('Gagal melakukan pencarian: $e');
    }
  }

  void _resetClient() {
    _yt.close();
    _initClient();
  }

  void dispose() {
    _yt.close();
  }
}
