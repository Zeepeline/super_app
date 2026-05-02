import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/track_entity.dart';
import '../../domain/entities/playlist_entity.dart';

abstract class HomeRepository {
  Future<Either<Failure, List<TrackEntity>>> getPopularTracks();
  Future<Either<Failure, List<PlaylistEntity>>> getFeaturedPlaylists();
  Future<Either<Failure, void>> deleteTrack(String id);
  Stream<void> watchTracks();
}
