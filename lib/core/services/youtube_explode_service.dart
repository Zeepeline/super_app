import 'package:flutter/foundation.dart';
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

  /// Get video metadata by ID.
  Future<Video> getVideoMetadata(String videoId) async {
    try {
      return await _yt.videos.get(videoId);
    } catch (e) {
      debugPrint('YouTube Get Video Error: $e');
      throw Exception('Gagal mengambil data video: $e');
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
