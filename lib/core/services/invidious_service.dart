import "package:flutter/foundation.dart";
import 'package:dio/dio.dart';

class InvidiousService {
  final Dio _dio = Dio();

  // List of public Invidious instances
  final List<String> _instances = [
    'https://yewtu.be/',
    // 'https://inv.tux.pizza/',
    'https://invidious.nerdvpn.de/',
    'https://inv.vern.cc/',
    'https://invidious.flokinet.to/',
  ];

  Future<String?> getAudioStreamUrl(String videoId) async {
    for (var instance in _instances) {
      try {
        debugPrint("InvidiousService: Trying instance $instance for $videoId");
        final response = await _dio.get(
          '${instance}api/v1/videos/$videoId',
          options: Options(
            receiveTimeout: const Duration(seconds: 10),
            sendTimeout: const Duration(seconds: 10),
          ),
        );

        if (response.statusCode == 200) {
          final data = response.data;
          final adaptiveFormats = data['adaptiveFormats'] as List;

          // Find audio-only streams
          final audioStreams = adaptiveFormats.where((f) {
            final type = f['type']?.toString() ?? '';
            final container = f['container']?.toString() ?? '';
            return type.contains('audio') ||
                container == 'm4a' ||
                container == 'webm';
          }).toList();

          if (audioStreams.isNotEmpty) {
            // Prefer higher bitrate
            audioStreams.sort((a, b) {
              final brA = int.tryParse(a['bitrate']?.toString() ?? '0') ?? 0;
              final brB = int.tryParse(b['bitrate']?.toString() ?? '0') ?? 0;
              return brB.compareTo(brA);
            });

            final streamUrl = audioStreams.first['url'] as String;
            debugPrint("InvidiousService: Successfully found audio stream");
            return streamUrl;
          }
        }
      } catch (e) {
        debugPrint("InvidiousService Warning: Instance $instance failed: $e");
      }
    }
    debugPrint("InvidiousService Error: All instances failed.");
    return null;
  }
}
