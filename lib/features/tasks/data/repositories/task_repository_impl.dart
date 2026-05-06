import 'package:dartz/dartz.dart';
import 'package:super_app/features/tasks/data/datasources/task_local_datasource.dart';
import 'package:super_app/features/tasks/data/models/task_model.dart';
import 'package:super_app/features/tasks/domain/entities/task_entity.dart';
import 'package:super_app/features/tasks/domain/repositories/task_repository.dart';

import '../../../../core/error/failures.dart';

class TaskRepositoryImpl implements TaskRepository {
  final TaskLocalDataSource localDataSource;

  TaskRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, void>> addTask(TaskEntity task) async {
    try {
      final model = TaskModel(
        id: task.id,
        title: task.title,
        description: task.description,
        category: task.category,
        priority: task.priority.toString().split('.').last,
        dueDate: task.dueDate,
        time: task.time,
        endTime: task.endTime,
        isCompleted: task.isCompleted,
        subTasks: task.subTasks,
      );
      await localDataSource.cacheTask(model);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TaskEntity>>> getTasks() async {
    try {
      final models = await localDataSource.getTasks();
      final entities = models
          .map(
            (m) => TaskEntity(
              id: m.id,
              title: m.title,
              description: m.description,
              category: m.category,
              priority: _parsePriority(m.priority),
              dueDate: m.dueDate,
              time: m.time,
              endTime: m.endTime,
              isCompleted: m.isCompleted,
              subTasks: m.subTasks,
            ),
          )
          .toList();
      return Right(entities);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTask(String id) async {
    try {
      await localDataSource.deleteTask(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateTask(TaskEntity task) async {
    try {
      final model = TaskModel(
        id: task.id,
        title: task.title,
        description: task.description,
        category: task.category,
        priority: task.priority.toString().split('.').last,
        dueDate: task.dueDate,
        time: task.time,
        endTime: task.endTime,
        isCompleted: task.isCompleted,
        subTasks: task.subTasks,
      );
      await localDataSource.updateTask(model);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  TaskPriority _parsePriority(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return TaskPriority.high;
      case 'low':
        return TaskPriority.low;
      default:
        return TaskPriority.medium;
    }
  }
}
