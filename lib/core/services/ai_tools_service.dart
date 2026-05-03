import '../../features/home/data/datasources/home_local_data_source.dart';
import '../../features/home/data/models/track_model.dart' as home;
import '../../features/music_player/data/models/track_model.dart' as player;
import '../../features/music_player/domain/repositories/music_repository.dart';

class AiToolsService {
  final MusicRepository _musicRepository;
  final HomeLocalDataSource _localDataSource;

  AiToolsService(this._musicRepository, this._localDataSource);

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

  /// Statistik library untuk konteks AI.
  Future<String> getLibrarySummary() async {
    final tracks = await _localDataSource.getPopularTracks();
    if (tracks.isEmpty) return "Library musik Anda kosong.";

    return "Anda memiliki ${tracks.length} lagu di library lokal.";
  }
}
