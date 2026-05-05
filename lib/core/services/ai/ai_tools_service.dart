import 'package:super_app/core/services/download/youtube_explode_service.dart';
import 'package:super_app/core/services/infrastructure/native_device_service.dart';
import 'package:super_app/core/services/download/youtube_download_service.dart';
import 'package:super_app/core/services/books/book_library_service.dart';
import 'package:super_app/features/book_collection/data/models/local_book.dart';
import 'package:super_app/features/home/data/datasources/home_local_data_source.dart';
import 'package:super_app/features/home/data/models/track_model.dart' as home;
import 'package:super_app/features/music_player/data/models/track_model.dart'
    as player;
import 'package:super_app/features/music_player/domain/repositories/music_repository.dart';

import 'user_memory_service.dart';

class AiToolsService {
  final MusicRepository _musicRepository;
  final HomeLocalDataSource _localDataSource;
  final UserMemoryService _memoryService;
  final NativeDeviceService _nativeService;
  final YoutubeDownloadService _downloadService;
  final YouTubeExplodeService _ytService;
  final BookLibraryService _bookService;

  AiToolsService(
    this._musicRepository,
    this._localDataSource,
    this._memoryService,
    this._nativeService,
    this._downloadService,
    this._ytService,
    this._bookService,
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
                (t.plainLyricsField?.toLowerCase().contains(query.toLowerCase()) ??
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
      String videoUrl = query;
      String trackTitle = query;

      // If not a URL, search for it
      if (!query.contains('youtube.com') && !query.contains('youtu.be')) {
        final searchResults = await _ytService.searchVideos(query);
        if (searchResults.isEmpty) {
          return "Maaf, saya tidak menemukan lagu '$query' di YouTube.";
        }
        final firstVideo = searchResults.first;
        videoUrl = "https://www.youtube.com/watch?v=${firstVideo.id}";
        trackTitle = firstVideo.title;
      }

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

      return "Mulai mendownload: $trackTitle. Lagu akan muncul di library setelah selesai.";
    } catch (e) {
      return "Gagal inisialisasi download: $e";
    }
  }
}
