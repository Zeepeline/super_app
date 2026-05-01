import "package:flutter/foundation.dart";
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:html/parser.dart' show parse;

class Y2MateService {
  final Dio _dio;
  static const String mainSite = 'https://v1.y2mate.nu';

  // Backends can vary, but etacloud.org is the most common for y2mate clones
  String _backendUrl = 'https://eta.etacloud.org';
  String _authParamKey = 'p';

  Y2MateService(this._dio);

  Future<String?> getDownloadUrl(String youtubeUrl) async {
    try {
      // 1. Fetch the main page to get auth data and current backend domain
      final response = await _dio.get(
        mainSite,
        options: Options(headers: _getStandardHeaders()),
      );

      final html = response.data.toString();
      final jsonArray = _extractJsonArray(html);
      if (jsonArray == null) {
        throw Exception("Could not find auth data on y2mate");
      }

      // Update backend domain and auth key if found
      _updateBackendConfig(html, jsonArray);

      final authToken = _calculateAuthToken(jsonArray);
      final videoId = _extractVideoId(youtubeUrl);
      if (videoId == null) throw Exception("Invalid YouTube URL");

      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      // 2. Initialize conversion (GET /api/v1/init)
      final initResponse = await _dio.get(
        '$_backendUrl/api/v1/init',
        queryParameters: {
          'v': videoId,
          _authParamKey: authToken,
          't': timestamp,
        },
        options: Options(headers: _getStandardHeaders()),
      );

      final initData = initResponse.data;
      if (initData['error'] == true) {
        throw Exception("Y2Mate Init Error: ${initData['message']}");
      }

      // 3. Start conversion (GET /api/v1/convert)
      final convertResponse = await _dio.get(
        '$_backendUrl/api/v1/convert',
        queryParameters: {
          'v': videoId,
          _authParamKey: authToken,
          't': timestamp,
          'ftype': 'mp3',
          'fquality': '128',
        },
        options: Options(headers: _getStandardHeaders()),
      );

      final convertData = convertResponse.data;
      if (convertData['error'] == true) {
        throw Exception("Y2Mate Convert Error: ${convertData['message']}");
      }

      final progressUrl = '$_backendUrl/api/v1/status';

      // 4. Poll progress until finished
      return await _pollProgress(progressUrl, videoId, authToken);
    } catch (e) {
      debugPrint("Y2Mate Service Error: $e");
      return null;
    }
  }

  Map<String, String> _getStandardHeaders() {
    return {
      'User-Agent':
          'Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1',
      'Accept': 'application/json, text/plain, */*',
      'Origin': mainSite,
      'Referer': '$mainSite/',
    };
  }

  void _updateBackendConfig(String html, List<dynamic> json) {
    // Extract gB backend domain if present in JS
    final gBRegex = RegExp('var gB = ["\']([^"\']+)["\']');
    final match = gBRegex.firstMatch(html);
    if (match != null) {
      _backendUrl = 'https://eta.${match.group(1)}';
    }

    // Dynamic auth key from json[6]
    if (json.length > 6) {
      _authParamKey = String.fromCharCode(json[6] as int);
    }
  }

  List<dynamic>? _extractJsonArray(String html) {
    final document = parse(html);
    final scripts = document.getElementsByTagName('script');

    for (var script in scripts) {
      final content = script.text;
      if (content.contains('var json = JSON.parse(')) {
        final start = content.indexOf("JSON.parse('") + 12;
        final end = content.indexOf("')", start);
        if (start > 11 && end > start) {
          final jsonString = content.substring(start, end);
          return jsonDecode(jsonString);
        }
      }
    }
    return null;
  }

  String _calculateAuthToken(List<dynamic> json) {
    final list0 = json[0] as List<dynamic>;
    final list2 = json[2] as List<dynamic>;

    String token = "";
    for (int i = 0; i < list0.length; i++) {
      final val0 = (list0[i] as num).toInt();
      final val2 = (list2[list2.length - (i + 1)] as num).toInt();
      token += String.fromCharCode(val0 - val2);
    }
    return token;
  }

  String? _extractVideoId(String url) {
    if (url.contains('v=')) {
      return url.split('v=')[1].split('&')[0];
    } else if (url.contains('shorts/')) {
      return url.split('shorts/')[1].split('?')[0];
    } else if (url.contains('youtu.be/')) {
      return url.split('youtu.be/')[1].split('?')[0];
    }
    return null;
  }

  Future<String?> _pollProgress(
    String progressUrl,
    String videoId,
    String authToken,
  ) async {
    int attempts = 0;
    while (attempts < 60) {
      attempts++;
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      final response = await _dio.get(
        progressUrl,
        queryParameters: {
          'v': videoId,
          _authParamKey: authToken,
          't': timestamp,
        },
        options: Options(headers: _getStandardHeaders()),
      );

      final data = response.data;
      final progress = data['progress'] as int?;

      if (progress == 3) {
        return data['downloadURL'] as String?;
      } else if (progress == 4 || data['error'] == true) {
        throw Exception("Y2Mate conversion failed");
      }

      await Future.delayed(const Duration(seconds: 2));
    }
    throw Exception("Conversion timed out");
  }
}
