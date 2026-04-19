import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/track_entity.dart';
import '../repositories/home_repository.dart';

class GetFavoriteTracks implements UseCase<List<TrackEntity>, NoParams> {
  final HomeRepository repository;

  GetFavoriteTracks(this.repository);

  @override
  Future<Either<Failure, List<TrackEntity>>> call(NoParams params) async {
    final result = await repository.getPopularTracks();
    return result.fold(
      (failure) => Left(failure),
      (tracks) => Right(tracks.where((t) => t.isFavorite).toList()),
    );
  }
}
