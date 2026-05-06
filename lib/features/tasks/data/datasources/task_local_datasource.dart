import 'package:hive/hive.dart';
import '../../../../core/error/exceptions.dart';
import '../models/task_model.dart';

abstract class TaskLocalDataSource {
  Future<void> cacheTask(TaskModel task);
  Future<List<TaskModel>> getTasks();
  Future<void> deleteTask(String id);
  Future<void> updateTask(TaskModel task);
}

class TaskLocalDataSourceImpl implements TaskLocalDataSource {
  final Box<TaskModel> taskBox;

  TaskLocalDataSourceImpl({required this.taskBox});

  @override
  Future<void> cacheTask(TaskModel task) async {
    try {
      await taskBox.put(task.id, task);
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<List<TaskModel>> getTasks() async {
    try {
      return taskBox.values.toList();
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<void> deleteTask(String id) async {
    try {
      await taskBox.delete(id);
    } catch (e) {
      throw CacheException(e.toString());
    }
  }

  @override
  Future<void> updateTask(TaskModel task) async {
    try {
      await taskBox.put(task.id, task);
    } catch (e) {
      throw CacheException(e.toString());
    }
  }
}
