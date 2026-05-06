import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/holiday_entity.dart';
import '../../domain/repositories/holiday_repository.dart';
import '../datasources/holiday_local_datasource.dart';
import '../datasources/holiday_remote_datasource.dart';

class HolidayRepositoryImpl implements HolidayRepository {
  final HolidayRemoteDataSource remoteDataSource;
  final HolidayLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  HolidayRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<HolidayEntity>>> getHolidays(int year) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteHolidays = await remoteDataSource.getHolidays(year);
        await localDataSource.cacheHolidays(year, remoteHolidays);
        return Right(remoteHolidays);
      } catch (e) {
        // Fallback to cache if remote fails
        final localHolidays = await localDataSource.getCachedHolidays(year);
        if (localHolidays.isNotEmpty) {
          return Right(localHolidays);
        }
        return Left(ServerFailure(e.toString()));
      }
    } else {
      final localHolidays = await localDataSource.getCachedHolidays(year);
      if (localHolidays.isNotEmpty) {
        return Right(localHolidays);
      }
      return const Left(CacheFailure('No internet connection and no cached data found.'));
    }
  }
}
