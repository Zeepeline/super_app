import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:super_app/core/services/media/lyrics_service.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late LyricsService lyricsService;
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    lyricsService = LyricsService(mockDio);
  });

  group('LyricsService - parseLrc', () {
    test('should parse valid LRC string correctly', () {
      final lrc = '[00:12.34] Line 1\n[00:15.50] Line 2';
      final result = lyricsService.parseLrc(lrc);

      expect(result.length, 2);
      expect(result[0].text, 'Line 1');
      expect(result[0].startTime.inMilliseconds, 12340);
      expect(result[1].text, 'Line 2');
      expect(result[1].startTime.inMilliseconds, 15500);
    });

    test('should handle multiple timestamps on one line', () {
      final lrc = '[00:12.34][00:20.00] Repeated Line';
      final result = lyricsService.parseLrc(lrc);

      expect(result.length, 2);
      expect(result[0].text, 'Repeated Line');
      expect(result[0].startTime.inSeconds, 12);
      expect(result[1].text, 'Repeated Line');
      expect(result[1].startTime.inSeconds, 20);
    });

    test('should handle 3-digit milliseconds', () {
      final lrc = '[00:12.345] Line with 3 digits';
      final result = lyricsService.parseLrc(lrc);

      expect(result[0].startTime.inMilliseconds, 12345);
    });

    test('should handle 1-digit milliseconds', () {
      final lrc = '[00:12.3] Line with 1 digit';
      final result = lyricsService.parseLrc(lrc);

      expect(result[0].startTime.inMilliseconds, 12300);
    });

    test('should clean tags from text', () {
      final lrc = '[00:10.00] Some text [extra tag]';
      final result = lyricsService.parseLrc(lrc);
      expect(result[0].text, 'Some text');
    });
  });
}
