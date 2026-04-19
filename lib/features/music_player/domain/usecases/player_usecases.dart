import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:super_app/core/error/failures.dart';
import 'package:super_app/core/usecases/usecase.dart';
import 'package:super_app/features/music_player/domain/entities/track_entity.dart';
import 'package:super_app/features/music_player/domain/repositories/music_repository.dart';

class PlayTrack implements UseCase<TrackEntity, TrackParams> {
  final MusicRepository repository;

  PlayTrack(this.repository);

  @override
  Future<Either<Failure, TrackEntity>> call(TrackParams params) async {
    return await repository.playTrack(params.trackId);
  }
}

class PauseTrack implements UseCase<TrackEntity, NoParams> {
  final MusicRepository repository;

  PauseTrack(this.repository);

  @override
  Future<Either<Failure, TrackEntity>> call(NoParams params) async {
    return await repository.pauseTrack();
  }
}

class SeekTo implements UseCase<TrackEntity, SeekParams> {
  final MusicRepository repository;

  SeekTo(this.repository);

  @override
  Future<Either<Failure, TrackEntity>> call(SeekParams params) async {
    return await repository.seekTo(params.position);
  }
}

class ToggleFavorite implements UseCase<TrackEntity, TrackParams> {
  final MusicRepository repository;

  ToggleFavorite(this.repository);

  @override
  Future<Either<Failure, TrackEntity>> call(TrackParams params) async {
    return await repository.toggleFavorite(params.trackId);
  }
}

class SkipToNext implements UseCase<TrackEntity, NoParams> {
  final MusicRepository repository;

  SkipToNext(this.repository);

  @override
  Future<Either<Failure, TrackEntity>> call(NoParams params) async {
    return await repository.skipToNext();
  }
}

class SkipToPrevious implements UseCase<TrackEntity, NoParams> {
  final MusicRepository repository;

  SkipToPrevious(this.repository);

  @override
  Future<Either<Failure, TrackEntity>> call(NoParams params) async {
    return await repository.skipToPrevious();
  }
}

class ToggleShuffle implements UseCase<TrackEntity, NoParams> {
  final MusicRepository repository;

  ToggleShuffle(this.repository);

  @override
  Future<Either<Failure, TrackEntity>> call(NoParams params) async {
    return await repository.toggleShuffle();
  }
}

class ToggleRepeat implements UseCase<TrackEntity, NoParams> {
  final MusicRepository repository;

  ToggleRepeat(this.repository);

  @override
  Future<Either<Failure, TrackEntity>> call(NoParams params) async {
    return await repository.toggleRepeat();
  }
}

class TrackParams extends Equatable {
  final String trackId;

  const TrackParams({required this.trackId});

  @override
  List<Object> get props => [trackId];
}

class SeekParams extends Equatable {
  final Duration position;

  const SeekParams({required this.position});

  @override
  List<Object> get props => [position];
}
