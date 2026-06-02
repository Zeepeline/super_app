import 'package:flutter_test/flutter_test.dart';
import 'package:super_app/core/services/media/lyrics_service.dart';
import 'package:super_app/features/music_player/domain/models/lyric_line.dart';
import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';

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
      const LyricLine(startTime: Duration(seconds: 0), text: 'Line 1'),
      const LyricLine(startTime: Duration(seconds: 5), text: 'Line 2'),
      const LyricLine(startTime: Duration(seconds: 10), text: 'Line 3'),
      const LyricLine(startTime: Duration(seconds: 15), text: 'Line 4'),
      const LyricLine(startTime: Duration(seconds: 20), text: 'Line 5'),
    ];

    test('should return -1 when lyrics list is empty', () {
      final index = lyricsService.findActiveIndex(
        [],
        const Duration(seconds: 10),
      );
      expect(index, -1);
    });

    test('should return -1 when position is before the first lyric', () {
      final index = lyricsService.findActiveIndex(
        lyrics,
        const Duration(seconds: -1),
      );
      expect(index, -1);
    });

    test(
      'should return 0 when position is exactly at the first lyric start time',
      () {
        final index = lyricsService.findActiveIndex(
          lyrics,
          const Duration(seconds: 0),
        );
        expect(index, 0);
      },
    );

    test('should return correct index for mid-song position', () {
      final index = lyricsService.findActiveIndex(
        lyrics,
        const Duration(seconds: 7),
      );
      expect(index, 1);
    });

    test(
      'should return correct index when exactly matching a lyric start time',
      () {
        final index = lyricsService.findActiveIndex(
          lyrics,
          const Duration(seconds: 15),
        );
        expect(index, 3);
      },
    );

    test('should return last index when position is beyond the last lyric', () {
      final index = lyricsService.findActiveIndex(
        lyrics,
        const Duration(seconds: 100),
      );
      expect(index, 4);
    });

    test('should handle single lyric line', () {
      final singleLine = [
        const LyricLine(startTime: Duration(seconds: 5), text: 'Only line'),
      ];
      expect(
        lyricsService.findActiveIndex(singleLine, const Duration(seconds: 2)),
        -1,
      );
      expect(
        lyricsService.findActiveIndex(singleLine, const Duration(seconds: 5)),
        0,
      );
      expect(
        lyricsService.findActiveIndex(singleLine, const Duration(seconds: 10)),
        0,
      );
    });
    group('Binary Search Edge Cases', () {
      test('should find correct index in large list', () {
        final largeLyrics = List.generate(
          1000,
          (i) => LyricLine(
            startTime: Duration(seconds: i),
            text: 'Line $i',
          ),
        );

        expect(
          lyricsService.findActiveIndex(
            largeLyrics,
            const Duration(milliseconds: 500),
          ),
          0,
        );
        expect(
          lyricsService.findActiveIndex(
            largeLyrics,
            const Duration(seconds: 500, milliseconds: 500),
          ),
          500,
        );
        expect(
          lyricsService.findActiveIndex(
            largeLyrics,
            const Duration(seconds: 999, milliseconds: 999),
          ),
          999,
        );
      });
    });
  });
}
