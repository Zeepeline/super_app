import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:yt_downloader/yt_downloader.dart' as ytd;

import '../../features/home/data/models/track_model.dart';
import './lyrics_service.dart';

class YoutubeDownloadService {
  final LyricsService _lyricsService;
  final YoutubeExplode _yt = YoutubeExplode();

  // Pre-compiled RegExps for performance optimization
  static final RegExp _illegalChars = RegExp(r'[<>:"/\\|?*]');
  static final RegExp _controlChars = RegExp(r'[\x00-\x1F\x7F]');
  final ytd.YtDownloader _ytDownloader = ytd.YtDownloader();

  YoutubeDownloadService(this._lyricsService);

  Future<TrackModel?> downloadAndConvert({
    required String url,
    Function(String stage, double progress)? onProgress,
  }) async {
    try {
      // 1. Get Metadata (Lightweight)
      onProgress?.call('Fetching metadata...', 0.05);

      final VideoId videoId;
      try {
        final parsedId = VideoId.parseVideoId(url);
        videoId = VideoId(parsedId ?? url);
      } catch (e) {
        debugPrint("YoutubeDownloadService: Invalid URL format: $url");
        return null;
      }

      Video? video;
      try {
        video = await _yt.videos
            .get(videoId)
            .timeout(const Duration(seconds: 10));
      } catch (e) {
        debugPrint("YoutubeDownloadService: Metadata fetch failed: $e.");
      }
      debugPrint("YoutubeDownloadService: YT Downloader 0");

      final title = video?.title ?? "Unknown Title";
      final author = video?.author ?? "Unknown Artist";
      final thumbnail = video?.thumbnails.highResUrl ?? "";
      final duration = video?.duration?.toString() ?? '0:00:00';
      debugPrint("YoutubeDownloadService: YT Downloader 1");

      final appDir = await getApplicationDocumentsDirectory();
      final musicDir = Directory(p.join(appDir.path, 'music'));
      if (!await musicDir.exists()) await musicDir.create(recursive: true);

      // Sanitize title for filename
      final sanitizedTitle = _sanitizeFilename(title);
      final finalPath = p.join(
        musicDir.path,
        "$sanitizedTitle [${videoId.value}].mp3",
      );

      // 2. Stage 1: Platform-Specific Package (Gold Standard)

      // ANDROID: Use Extractor (yt-dlp)

      // IOS: Use yt_downloader
      debugPrint("YoutubeDownloadService: YT Downloader 2");

      onProgress?.call('Fetching lyrics...', 0.12);
      final lyrics = await _lyricsService.fetchLyrics(
        author,
        title,
        youtubeId: videoId.value,
      );
      final syncedLyrics = lyrics['synced'];
      final plainLyrics = lyrics['plain'];

      onProgress?.call('Downloading (via YT Downloader)...', 0.15);
      try {
        final info = await _ytDownloader.getInfo(url);
        // Prefer high quality audio

        await info.download(
          format: info.formats.best!,
          outputPath: finalPath,
          onProgress: (progress) {
            onProgress?.call(
              'Downloading: ${(progress * 100).toInt()}%',
              0.15 + (progress * 0.8),
            );
          },
        );

        onProgress?.call('Finished!', 1.0);
        return _createTrackModel(
          videoId.value,
          title,
          author,
          thumbnail,
          duration,
          url,
          finalPath,
          syncedLyrics,
          plainLyrics,
        );
      } catch (e) {
        debugPrint("YoutubeDownloadService: YT Downloader failed: $e");
      }

      debugPrint("YoutubeDownloadService: All download methods failed.");
      return null;
    } catch (e) {
      debugPrint("Youtube Download Error: $e");
      return null;
    }
  }

  TrackModel _createTrackModel(
    String id,
    String title,
    String author,
    String thumb,
    String duration,
    String url,
    String path,
    String? syncedLyrics,
    String? plainLyrics,
  ) {
    return TrackModel(
      idField: id,
      titleField: title,
      artistField: author,
      albumArtUrlField: thumb,
      durationField: duration,
      audioUrlField: url,
      localPathField: path,
      syncedLyricsField: syncedLyrics,
      plainLyricsField: plainLyrics,
    );
  }

  String _sanitizeFilename(String name) {
    // Character that are illegal in Windows/macOS/Linux filenames
    // Replace with underscores using pre-compiled RegExp
    String sanitized = name.replaceAll(_illegalChars, '_');
    // Remove control characters using pre-compiled RegExp
    sanitized = sanitized.replaceAll(_controlChars, '');
    // Trim and handle extremely long names (max 200 chars to be safe)
    sanitized = sanitized.trim();
    if (sanitized.length > 200) {
      sanitized = sanitized.substring(0, 200);
    }
    return sanitized.isEmpty ? 'download' : sanitized;
  }

  void dispose() {
    _yt.close();
  }
}
