import 'package:equatable/equatable.dart';

class HolidayEntity extends Equatable {
  final DateTime date;
  final String name;
  final bool isNationalHoliday;

  const HolidayEntity({
    required this.date,
    required this.name,
    this.isNationalHoliday = true,
  });

  @override
  List<Object?> get props => [date, name, isNationalHoliday];
}
