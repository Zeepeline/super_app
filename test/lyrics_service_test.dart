import 'package:flutter_test/flutter_test.dart';
import 'package:super_app/core/services/lyrics_service.dart';
import 'package:dio/dio.dart';

class FakeDio extends Fake implements Dio {}

void main() {
  late LyricsService lyricsService;
  late FakeDio fakeDio;

  setUp(() {
    fakeDio = FakeDio();
    lyricsService = LyricsService(fakeDio);
  });

  group('LyricsService - parseLrc', () {
    test('should parse LRC correctly', () {
      const lrc = '[00:12.34] Line 1\n[00:15.00] Line 2';
      final result = lyricsService.parseLrc(lrc);
      expect(result.length, 2);
      expect(result[0].text, 'Line 1');
      expect(result[0].startTime.inMilliseconds, 12340);
      expect(result[1].text, 'Line 2');
      expect(result[1].startTime.inMilliseconds, 15000);
    });

    test('should handle multiple timestamps on same line', () {
      const lrc = '[00:12.34][00:20.00] Multiple';
      final result = lyricsService.parseLrc(lrc);
      expect(result.length, 2);
      expect(result[0].startTime.inMilliseconds, 12340);
      expect(result[1].startTime.inMilliseconds, 20000);
      expect(result[0].text, 'Multiple');
      expect(result[1].text, 'Multiple');
    });
  });
}
