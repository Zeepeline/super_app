import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:super_app/core/services/ai/gemini_service.dart';
import 'package:super_app/core/services/books/book_library_service.dart';
import 'package:super_app/core/services/download/youtube_download_service.dart';
import 'package:super_app/core/services/download/youtube_explode_service.dart';
import 'package:super_app/core/services/infrastructure/native_device_service.dart';
import 'package:super_app/core/utils/hive_box_constants.dart';
import 'package:super_app/features/home/data/datasources/home_local_data_source.dart';
import 'package:super_app/features/home/data/models/track_model.dart' as home;
import 'package:super_app/features/music_player/data/models/track_model.dart'
    as player;
import 'package:super_app/features/music_player/domain/repositories/music_repository.dart';
import 'package:super_app/features/tasks/data/models/task_model.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../music/smart_playlist_service.dart';
import 'user_memory_service.dart';

class AiToolsService {
  final MusicRepository _musicRepository;
  final HomeLocalDataSource _localDataSource;
  final UserMemoryService _memoryService;
  final NativeDeviceService _nativeService;
  final YoutubeDownloadService _downloadService;
  final YouTubeExplodeService _ytService;
  final BookLibraryService _bookService;
  final GeminiService _geminiService;
  final SmartPlaylistService _smartPlaylistService;

  AiToolsService(
    this._musicRepository,
    this._localDataSource,
    this._memoryService,
    this._nativeService,
    this._downloadService,
    this._ytService,
    this._bookService,
    this._geminiService,
    this._smartPlaylistService,
  );

  UserMemoryService getMemoryService() => _memoryService;

  /// Mencari dan memutar lagu berdasarkan judul atau ID.
  Future<String> playTrack(String query) async {
    try {
      final tracks = await _localDataSource.getPopularTracks();

      // Cari yang paling mirip judulnya atau ID
      final homeTrack = tracks.firstWhere(
        (t) =>
            t.titleField.toLowerCase().contains(query.toLowerCase()) ||
            t.idField == query,
        orElse: () => throw "Lagu '$query' tidak ditemukan di library Anda.",
      );

      // Konversi home/TrackModel ke music_player/TrackModel untuk AudioHandler
      final playerTrack = _convertToPlayerTrack(homeTrack);

      await _musicRepository.playTrack(playerTrack.id, track: playerTrack);
      return "Berhasil memutar lagu: ${homeTrack.titleField} oleh ${homeTrack.artistField}";
    } catch (e) {
      return "Gagal memutar lagu: $e";
    }
  }

  player.TrackModel _convertToPlayerTrack(home.TrackModel t) {
    // Parse duration string "m:ss" to Duration
    final parts = t.durationField.split(':');
    int minutes = 0;
    int seconds = 0;
    if (parts.length > 1) {
      minutes = int.tryParse(parts[0]) ?? 0;
      seconds = int.tryParse(parts[1]) ?? 0;
    } else {
      seconds = int.tryParse(parts[0]) ?? 0;
    }

    return player.TrackModel(
      id: t.idField,
      title: t.titleField,
      artist: t.artistField,
      album: t.albumField,
      albumArtUrl: t.albumArtUrlField,
      duration: Duration(minutes: minutes, seconds: seconds),
      audioUrl: t.audioUrlField,
      localPath: t.localPathField,
      syncedLyrics: t.syncedLyricsField,
      plainLyrics: t.plainLyricsField,
      isFavorite: t.isFavoriteField,
    );
  }

  /// Menjedakan musik.
  Future<String> pauseMusic() async {
    await _musicRepository.pauseTrack();
    return "Musik dihentikan sementara.";
  }

  /// Melanjutkan musik.
  Future<String> resumeMusic() async {
    final current = await _musicRepository.getCurrentTrack();
    return current.fold((f) => "Gagal melanjutkan musik.", (t) async {
      await _musicRepository.playTrack(t.id);
      return "Musik dilanjutkan.";
    });
  }

  /// Lagu selanjutnya.
  Future<String> skipNext() async {
    await _musicRepository.skipToNext();
    return "Memutar lagu selanjutnya.";
  }

  /// Mencari lagu di library berdasarkan query teks umum.
  Future<String> searchLibrary(String query) async {
    try {
      final tracks = await _localDataSource.getPopularTracks();
      final results = tracks
          .where(
            (t) =>
                t.titleField.toLowerCase().contains(query.toLowerCase()) ||
                t.artistField.toLowerCase().contains(query.toLowerCase()) ||
                t.albumField.toLowerCase().contains(query.toLowerCase()) ||
                (t.plainLyricsField?.toLowerCase().contains(
                      query.toLowerCase(),
                    ) ??
                    false),
          )
          .toList();

      if (results.isEmpty)
        return "Tidak ditemukan lagu yang cocok dengan '$query' di library Anda.";

      final list = results
          .take(5)
          .map((t) => "- ${t.titleField} oleh ${t.artistField}")
          .join("\n");
      return "Ditemukan beberapa lagu:\n$list";
    } catch (e) {
      return "Gagal mencari di library: $e";
    }
  }

  /// Mencari buku di library lokal berdasarkan judul atau penulis.
  Future<String> searchBooks(String query) async {
    try {
      final books = await _bookService.getDownloadedBooks();
      final results = books
          .where(
            (b) =>
                b.title.toLowerCase().contains(query.toLowerCase()) ||
                b.author.toLowerCase().contains(query.toLowerCase()) ||
                (b.synopsis?.toLowerCase().contains(query.toLowerCase()) ??
                    false),
          )
          .toList();

      if (results.isEmpty) {
        return "Tidak ditemukan buku yang cocok dengan '$query' di koleksi Anda.";
      }

      final list = results
          .take(5)
          .map((b) => "- ${b.title} oleh ${b.author} (${b.format})")
          .join("\n");
      return "Ditemukan beberapa buku:\n$list";
    } catch (e) {
      return "Gagal mencari di koleksi buku: $e";
    }
  }

  /// Mendapatkan lirik lagu yang sedang diputar atau berdasarkan judul.
  Future<String> getLyrics(String query) async {
    try {
      final tracks = await _localDataSource.getPopularTracks();
      final track = tracks.firstWhere(
        (t) => t.titleField.toLowerCase().contains(query.toLowerCase()),
        orElse: () => throw "Lirik untuk '$query' tidak ditemukan.",
      );

      if (track.plainLyricsField == null || track.plainLyricsField!.isEmpty) {
        return "Lagu '${track.titleField}' ada, tapi liriknya belum tersedia.";
      }

      return "Berikut lirik lagu ${track.titleField}:\n\n${track.plainLyricsField}";
    } catch (e) {
      return "Maaf, saya tidak bisa menemukan liriknya: $e";
    }
  }

  /// Mendapatkan statistik library untuk konteks AI.
  Future<String> getLibrarySummary() async {
    final tracks = await _localDataSource.getPopularTracks();
    if (tracks.isEmpty) return "Library musik Anda kosong.";

    return "Anda memiliki ${tracks.length} lagu di library lokal.";
  }

  /// MEMORY: Menyimpan informasi penting tentang preferensi user.
  Future<String> saveUserFact(
    String subject,
    String predicate,
    String object,
  ) async {
    await _memoryService.saveFact(
      subject: subject,
      predicate: predicate,
      object: object,
    );
    return "Saya simpan di memori: $subject $predicate $object";
  }

  /// MEMORY: Mengambil semua memori tentang user untuk konteks.
  Future<String> getUserMemories() async {
    return _memoryService.getCompactMemory();
  }

  /// NATIVE: Mengatur volume sistem (0-100).
  Future<String> setSystemVolume(int percent) async {
    final level = percent / 100.0;
    await _nativeService.setVolume(level);
    return "Volume sistem diatur ke $percent%";
  }

  /// NATIVE: Mendapatkan status sistem (Baterai, Koneksi, dll).
  Future<String> getSystemStatus() async {
    final battery = await _nativeService.getBatteryLevel();
    final conn = await _nativeService.getConnectivityStatus();
    final volume = await _nativeService.getVolume();
    return "Status: Baterai $battery%, Koneksi $conn, Volume ${(volume * 100).toInt()}%";
  }

  /// NATIVE: Informasi Perangkat.
  Future<String> getDeviceInfo() async {
    final info = await _nativeService.getDeviceInfo();
    final app = await _nativeService.getAppInfo();
    return "Perangkat: ${info['model']}, OS: ${info['version']}. Aplikasi: $app";
  }

  /// DOWNLOAD: Mencari dan mendownload lagu dari YouTube.
  Future<String> downloadMusic(String query) async {
    try {
      String videoUrl = "";
      String trackTitle = "";
      Video? video;

      if (query.contains('youtube.com') || query.contains('youtu.be')) {
        // If it's a URL, get metadata first
        final videoId = VideoId.parseVideoId(query);
        if (videoId != null) {
          video = await _ytService.getVideoMetadata(videoId);
          videoUrl = query;
          trackTitle = video.title;
        }
      } else {
        // If not a URL, search for it
        final searchResults = await _ytService.searchVideos(query);
        if (searchResults.isEmpty) {
          return "Maaf, saya tidak menemukan lagu '$query' di YouTube.";
        }
        video = searchResults.first;
        videoUrl = "https://www.youtube.com/watch?v=${video.id.value}";
        trackTitle = video.title;
      }

      if (video == null) {
        return "Gagal mendapatkan informasi video untuk '$query'.";
      }

      final firstVideo = video; // For compatibility with my previous JSON block

      // Start the download in background
      _downloadService
          .downloadAndConvert(
            url: videoUrl,
            onProgress: (stage, progress) {
              // Progress logging can be added here
            },
          )
          .then((track) async {
            if (track != null) {
              await _localDataSource.addImportedTracks([track]);
            }
          })
          .catchError((e) {
            print("AiToolsService: Download error for $trackTitle: $e");
          });

      final json = jsonEncode({
        'videoId': firstVideo.id.value,
        'title': trackTitle,
        'thumbnail': firstVideo.thumbnails.mediumResUrl,
        'artist': firstVideo.author,
      });

      return "[DOWNLOAD_MUSIC_JSON: $json]";
    } catch (e) {
      return "Gagal inisialisasi download: $e";
    }
  }

  /// Mendapatkan rekomendasi tugas berdasarkan KB dan waktu saat ini.
  Future<String> recommendTask() async {
    try {
      final kbContent = await rootBundle.loadString(
        'assets/knowledge/productivity_kb.md',
      );
      final now = DateTime.now();
      final currentTime =
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

      // Ambil memori user untuk personalisasi tambahan
      final userContext = await getUserMemories();

      return await _geminiService.getTaskRecommendation(
        kbContent: kbContent,
        currentTime: currentTime,
        userContext: userContext,
      );
    } catch (e) {
      return "Error recommending task: $e";
    }
  }

  /// Memberikan insight cerdas untuk UI (Smart Notification Card)
  Future<String> getAiInsights() async {
    try {
      final now = DateTime.now();
      final userContext = await getUserMemories();

      // Ambil task mendatang jika ada
      String taskContext = "Tidak ada tugas mendesak.";
      try {
        final taskBox = await Hive.openBox<TaskModel>(
          HiveBoxConstants.tasksBox,
        );
        final upcoming = taskBox.values
            .where((t) => !t.isCompleted && t.dueDate.isAfter(now))
            .toList();
        if (upcoming.isNotEmpty) {
          taskContext =
              "Ada ${upcoming.length} tugas mendatang, terdekat adalah '${upcoming.first.title}'.";
        }
      } catch (_) {}

      final prompt =
          """
        Generate a very short, motivating, and personal "Daily Insight" for a mobile app home screen.
        Context:
        - Time: ${now.hour}:${now.minute}
        - User Memories: $userContext
        - Task Status: $taskContext
        
        Requirements:
        - Language: Indonesian.
        - Tone: Supportive, like a life coach.
        - Length: Max 15 words.
        - Purpose: Acts as a "Smart Notification" widget on the home page.
        - Do not use quotes in the response.
      """;

      return await _geminiService.getChatResponse(prompt);
    } catch (e) {
      return "Hari yang luar biasa untuk produktivitas! Apa rencana Anda hari ini?";
    }
  }

  /// Membuat playlist pintar
  Future<String> generateSmartPlaylist(String query) async {
    try {
      final playlist = await _smartPlaylistService.generateYouTubePlaylist(
        query,
      );
      if (playlist != null && playlist.tracks.isNotEmpty) {
        final json = jsonEncode({
          'playlistName': playlist.playlistName,
          'reason': playlist.reason,
          'tracks': playlist.tracks
              .map(
                (t) => {
                  'id': t.id,
                  'title': t.title,
                  'artist': t.artist,
                  'albumArtUrl': t.albumArtUrl,
                  'duration_seconds': t.duration.inSeconds,
                },
              )
              .toList(),
        });
        return "[SMART_PLAYLIST_JSON: $json]";
      }
      return "Maaf, saya tidak bisa menemukan lagu yang pas untuk playlist tersebut.";
    } catch (e) {
      return "Gagal membuat playlist pintar: $e";
    }
  }
}
