import '../models/dashboard_model.dart';

abstract class DashboardRemoteDataSource {
  Future<DashboardModel> getDashboardData();
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  @override
  Future<DashboardModel> getDashboardData() async {
    // Simulasi delay network
    await Future.delayed(const Duration(seconds: 1));

    return const DashboardModel(
      dailyStatus: [
        StatusModel(
          id: '1',
          type: 'next_up',
          title: 'NEXT UP',
          value: 'Mastering Session',
        ),
        StatusModel(
          id: '2',
          type: 'meeting',
          title: 'MEETING',
          value: 'Sync Mix',
        ),
        StatusModel(
          id: '3',
          type: 'readiness',
          title: 'READINESS',
          value: '92/100',
          progress: 0.92,
        ),
      ],
      activeTasks: [
        TaskModel(
          id: '1',
          title: 'Mastering Session',
          priority: 'high',
          estimatedTime: '2.5h est.',
          isCompleted: false,
        ),
        TaskModel(
          id: '2',
          title: 'Vocal Layering Analysis',
          priority: 'medium',
          estimatedTime: '1.7h est.',
          isCompleted: false,
        ),
        TaskModel(
          id: '3',
          title: 'Library Indexing',
          priority: 'low',
          estimatedTime: 'Completed 08:30 AM',
          isCompleted: true,
        ),
      ],
      trend: TrendModel(growth: '+14%', dataPoints: [0.2, 0.4, 0.6, 1.0, 0.7]),
      insightMessage:
          'Your focus peaked 2 hours earlier than yesterday. Maintain this morning momentum.',
    );
  }
}
