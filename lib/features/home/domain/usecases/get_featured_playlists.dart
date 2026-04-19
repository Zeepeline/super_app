import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/playlist_entity.dart';
import '../repositories/home_repository.dart';

class GetFeaturedPlaylists implements UseCase<List<PlaylistEntity>, NoParams> {
  final HomeRepository repository;

  GetFeaturedPlaylists(this.repository);

  @override
  Future<Either<Failure, List<PlaylistEntity>>> call(NoParams params) async {
    return await repository.getFeaturedPlaylists();
  }
}
