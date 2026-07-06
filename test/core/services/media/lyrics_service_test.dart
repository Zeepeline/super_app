import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:super_app/core/services/media/lyrics_service.dart';
import 'package:super_app/features/music_player/domain/models/lyric_line.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late LyricsService lyricsService;
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    lyricsService = LyricsService(mockDio);
  });

  group('LyricsService.findActiveIndex', () {
    final lyrics = [
      const LyricLine(startTime: Duration(seconds: 0), text: 'Line 0'),
      const LyricLine(startTime: Duration(seconds: 10), text: 'Line 10'),
      const LyricLine(startTime: Duration(seconds: 20), text: 'Line 20'),
      const LyricLine(startTime: Duration(seconds: 30), text: 'Line 30'),
    ];

    test('should return -1 if lyrics list is empty', () {
      final index = lyricsService.findActiveIndex([], const Duration(seconds: 5));
      expect(index, -1);
    });

    test('should return 0 for position at exactly first line start time', () {
      final index = lyricsService.findActiveIndex(lyrics, const Duration(seconds: 0));
      expect(index, 0);
    });

    test('should return 0 for position after first but before second line', () {
      final index = lyricsService.findActiveIndex(lyrics, const Duration(seconds: 5));
      expect(index, 0);
    });

    test('should return 1 for position at exactly second line start time', () {
      final index = lyricsService.findActiveIndex(lyrics, const Duration(seconds: 10));
      expect(index, 1);
    });

    test('should return last index for position after last line', () {
      final index = lyricsService.findActiveIndex(lyrics, const Duration(seconds: 100));
      expect(index, 3);
    });

    test('should return -1 for position before first line (if first line > 0)', () {
      final lyricsWithGap = [
        const LyricLine(startTime: Duration(seconds: 10), text: 'First line at 10s'),
      ];
      final index = lyricsService.findActiveIndex(lyricsWithGap, const Duration(seconds: 5));
      expect(index, -1);
    });

    test('should handle large number of lines correctly (stress test binary search logic)', () {
      final manyLyrics = List.generate(
        1000,
        (i) => LyricLine(startTime: Duration(seconds: i), text: 'Line $i'),
      );

      expect(lyricsService.findActiveIndex(manyLyrics, const Duration(milliseconds: 500)), 0);
      expect(lyricsService.findActiveIndex(manyLyrics, const Duration(milliseconds: 1500)), 1);
      expect(lyricsService.findActiveIndex(manyLyrics, const Duration(seconds: 500, milliseconds: 500)), 500);
      expect(lyricsService.findActiveIndex(manyLyrics, const Duration(seconds: 999)), 999);
      expect(lyricsService.findActiveIndex(manyLyrics, const Duration(seconds: 2000)), 999);
    });
   group('Binary midpoint calculation', () {
      test('should handle midpoint calculation correctly to avoid overflow and ensure progress', () {
        // This is more of a logic check for (low + high) >> 1
        final fewLyrics = [
          const LyricLine(startTime: Duration(seconds: 0), text: '0'),
          const LyricLine(startTime: Duration(seconds: 1), text: '1'),
        ];
        expect(lyricsService.findActiveIndex(fewLyrics, const Duration(milliseconds: 500)), 0);
        expect(lyricsService.findActiveIndex(fewLyrics, const Duration(milliseconds: 1500)), 1);
      });
    });
  });
}
