import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/session_entity.dart';
import '../repositories/schedule_repository.dart';

class GetSessions implements UseCase<List<SessionEntity>, DateTime> {
  final ScheduleRepository repository;

  GetSessions(this.repository);

  @override
  Future<Either<Failure, List<SessionEntity>>> call(DateTime params) async {
    return await repository.getSessionsByDate(params);
  }
}
