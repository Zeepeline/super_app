import 'package:hive/hive.dart';
import '../models/holiday_model.dart';

abstract class HolidayLocalDataSource {
  Future<void> cacheHolidays(int year, List<HolidayModel> holidays);
  Future<List<HolidayModel>> getCachedHolidays(int year);
}

class HolidayLocalDataSourceImpl implements HolidayLocalDataSource {
  final HiveInterface hive;

  HolidayLocalDataSourceImpl({required this.hive});

  String _getBoxKey(int year) => 'holidays_$year';

  @override
  Future<void> cacheHolidays(int year, List<HolidayModel> holidays) async {
    final box = await hive.openBox('holiday_cache');
    final data = holidays.map((h) => h.toJson()).toList();
    await box.put(_getBoxKey(year), data);
  }

  @override
  Future<List<HolidayModel>> getCachedHolidays(int year) async {
    final box = await hive.openBox('holiday_cache');
    final List<dynamic>? data = box.get(_getBoxKey(year));

    if (data != null) {
      return data
          .map((json) => HolidayModel.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    }
    return [];
  }
}
