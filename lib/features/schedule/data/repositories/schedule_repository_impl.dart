import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/session_entity.dart';
import '../../domain/repositories/schedule_repository.dart';
import '../datasources/schedule_remote_datasource.dart';

class ScheduleRepositoryImpl implements ScheduleRepository {
  final ScheduleRemoteDataSource remoteDataSource;

  ScheduleRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<SessionEntity>>> getSessionsByDate(DateTime date) async {
    try {
      final remoteSessions = await remoteDataSource.getSessionsByDate(date);
      return Right(remoteSessions);
    } on ServerException {
      return const Left(ServerFailure('Failed to load schedule from server'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
