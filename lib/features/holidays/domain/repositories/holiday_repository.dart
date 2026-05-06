import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/holiday_entity.dart';

abstract class HolidayRepository {
  Future<Either<Failure, List<HolidayEntity>>> getHolidays(int year);
}
