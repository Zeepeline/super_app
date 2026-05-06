import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/session_entity.dart';

abstract class ScheduleRepository {
  Future<Either<Failure, List<SessionEntity>>> getSessionsByDate(DateTime date);
}
