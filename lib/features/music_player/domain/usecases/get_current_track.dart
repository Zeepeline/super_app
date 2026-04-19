import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:super_app/core/error/failures.dart';
import 'package:super_app/core/usecases/usecase.dart';
import 'package:super_app/features/music_player/domain/entities/track_entity.dart';
import 'package:super_app/features/music_player/domain/repositories/music_repository.dart';

class GetCurrentTrack implements UseCase<TrackEntity, NoParams> {
  final MusicRepository repository;

  GetCurrentTrack(this.repository);

  @override
  Future<Either<Failure, TrackEntity>> call(NoParams params) async {
    return await repository.getCurrentTrack();
  }
}

class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object> get props => [];
}
