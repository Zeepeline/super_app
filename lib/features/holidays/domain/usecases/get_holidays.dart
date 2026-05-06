import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/holiday_entity.dart';
import '../repositories/holiday_repository.dart';

class GetHolidays implements UseCase<List<HolidayEntity>, int> {
  final HolidayRepository repository;

  GetHolidays(this.repository);

  @override
  Future<Either<Failure, List<HolidayEntity>>> call(int year) async {
    return await repository.getHolidays(year);
  }
}
