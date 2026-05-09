import 'package:dartz/dartz.dart';
import 'package:super_app/core/error/failures.dart';
import 'package:super_app/features/music_player/domain/entities/playlist_entity.dart';
import 'package:super_app/features/music_player/domain/entities/track_entity.dart';

abstract class MusicRepository {
  Future<Either<Failure, TrackEntity>> getCurrentTrack();

  Future<Either<Failure, PlaylistEntity>> getCurrentPlaylist();

  Future<void> initializePlayer();

  Future<Either<Failure, TrackEntity>> playTrack(
    String trackId, {
    TrackEntity? track,
  });

  Future<void> playPlaylist(List<TrackEntity> tracks);

  Future<Either<Failure, TrackEntity>> pauseTrack();

  Future<Either<Failure, TrackEntity>> seekTo(Duration position);

  Future<Either<Failure, TrackEntity>> toggleFavorite(String trackId);

  Future<Either<Failure, TrackEntity>> skipToNext();

  Future<Either<Failure, TrackEntity>> skipToPrevious();

  Future<Either<Failure, TrackEntity>> toggleShuffle();

  Future<Either<Failure, TrackEntity>> toggleRepeat();

  bool getShuffleState();

  bool getRepeatState();

  Stream<bool> get isPlayingStream;
  Stream<Duration> get positionStream;
  Stream<Duration?> get durationStream;
  Stream<TrackEntity?> get currentTrackStream;
  Future<void> saveLyrics(String path, String? synced, String? plain);
}
