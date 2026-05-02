import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/home_repository.dart';

class DeleteTrackUseCase implements UseCase<void, String> {
  final HomeRepository repository;

  DeleteTrackUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String params) async {
    return await repository.deleteTrack(params);
  }
}
