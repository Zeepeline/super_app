import '../models/session_model.dart';

abstract class ScheduleRemoteDataSource {
  Future<List<SessionModel>> getSessionsByDate(DateTime date);
}

class ScheduleRemoteDataSourceImpl implements ScheduleRemoteDataSource {
  @override
  Future<List<SessionModel>> getSessionsByDate(DateTime date) async {
    // Mock data for Oct 10, 2024 as seen in the design
    await Future.delayed(const Duration(milliseconds: 500));

    return [];
  }
}
