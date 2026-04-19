import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/playlist_entity.dart';
import '../../domain/entities/track_entity.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_local_data_source.dart';
import '../datasources/home_remote_datasource.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource remoteDataSource;
  final HomeLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  HomeRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<TrackEntity>>> getPopularTracks() async {
    try {
      final localTracks = await localDataSource.getPopularTracks();
      return Right(localTracks);
    } catch (e) {
      return const Left(CacheFailure('Failed to load local tracks'));
    }
  }

  @override
  Future<Either<Failure, List<PlaylistEntity>>> getFeaturedPlaylists() async {
    try {
      final localPlaylists = await localDataSource.getFeaturedPlaylists();
      return Right(localPlaylists);
    } catch (e) {
      return const Left(CacheFailure('Failed to load local playlists'));
    }
  }

  @override
  Stream<void> watchTracks() => localDataSource.watchTracks();
}
