import 'package:dartz/dartz.dart';
import 'package:super_app/features/tasks/domain/repositories/task_repository.dart'
    as task_repo;

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/dashboard_entity.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_remote_datasource.dart';
import '../models/dashboard_model.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource remoteDataSource;
  final task_repo.TaskRepository taskRepository;

  DashboardRepositoryImpl({
    required this.remoteDataSource,
    required this.taskRepository,
  });

  @override
  Future<Either<Failure, DashboardEntity>> getDashboardData() async {
    DashboardModel? remoteData;
    Failure? remoteFailure;

    try {
      remoteData = await remoteDataSource.getDashboardData();
    } on ServerException catch (e) {
      remoteFailure = ServerFailure(e.message);
    } catch (e) {
      remoteFailure = ServerFailure(e.toString());
    }

    // Fetch real tasks from TaskRepository (Always fetch local tasks)
    final tasksResult = await taskRepository.getTasks();

    return tasksResult.fold(
      (failure) {
        // If local tasks fetch fails, and remote failed, return failure
        if (remoteData == null) return Left(failure);

        // If local fails but we have remote, use remote
        return Right(remoteData);
      },
      (realTasks) {
        final mappedTasks = realTasks.map((t) {
          return TaskEntity(
            id: t.id,
            title: t.title,
            description: t.description,
            category: t.category,
            priority: t.priority,
            dueDate: t.dueDate,
            time: t.time,
            isCompleted: t.isCompleted,
            subTasks: t.subTasks,
          );
        }).toList();

        // Use remote data if available, otherwise use defaults
        final dailyStatus = remoteData?.dailyStatus ?? _getDefaultStatus();
        final trend =
            remoteData?.trend ??
            const TrendModel(
              growth: '0%',
              dataPoints: [0.5, 0.5, 0.5, 0.5, 0.5],
            );
        final insightMessage =
            remoteData?.insightMessage ??
            'Welcome back! Your sonic workflow is ready.';

        // Combine real tasks with remote tasks if needed, or just prioritize real ones
        final finalTasks = mappedTasks.isNotEmpty
            ? mappedTasks
            : (remoteData?.activeTasks ?? []);

        final updatedDashboard = DashboardEntity(
          dailyStatus: dailyStatus,
          activeTasks: finalTasks,
          trend: trend,
          insightMessage: insightMessage,
        );

        return Right(updatedDashboard);
      },
    );
  }

  List<StatusModel> _getDefaultStatus() {
    return const [
      StatusModel(
        id: 'default_1',
        type: 'readiness',
        title: 'READINESS',
        value: 'Ready',
        progress: 1.0,
      ),
    ];
  }
}
