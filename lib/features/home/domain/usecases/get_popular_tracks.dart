import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/track_entity.dart';
import '../repositories/home_repository.dart';

class GetPopularTracks implements UseCase<List<TrackEntity>, NoParams> {
  final HomeRepository repository;

  GetPopularTracks(this.repository);

  @override
  Future<Either<Failure, List<TrackEntity>>> call(NoParams params) async {
    return await repository.getPopularTracks();
  }
}
