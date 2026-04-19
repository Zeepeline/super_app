import '../models/playlist_model.dart';
import '../models/track_model.dart';

abstract class HomeRemoteDataSource {
  Future<List<TrackModel>> getPopularTracks();
  Future<List<PlaylistModel>> getFeaturedPlaylists();
}

class MockHomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  @override
  Future<List<TrackModel>> getPopularTracks() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      const TrackModel(
        idField: '1',
        titleField: 'Melodigne Champion',
        artistField: 'SoundWave Special',
        albumArtUrlField: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?auto=format&fit=crop&q=80&w=300',
        durationField: '3:45',
        audioUrlField: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
        localPathField: 'assets/music/melodigne-champion-143955.mp3',
      ),
      const TrackModel(
        idField: '2',
        titleField: 'Cyber Beats',
        artistField: 'Neon Pulse',
        albumArtUrlField: 'https://images.unsplash.com/photo-1493225255756-d9584f8606e9?auto=format&fit=crop&q=80&w=300',
        durationField: '3:50',
        audioUrlField: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
      ),
      const TrackModel(
        idField: '3',
        titleField: 'Synthwave Dreams',
        artistField: 'Night Drive',
        albumArtUrlField: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?auto=format&fit=crop&q=80&w=300',
        durationField: '3:20',
        audioUrlField: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
      ),
    ];
  }

  @override
  Future<List<PlaylistModel>> getFeaturedPlaylists() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [];
  }
}
