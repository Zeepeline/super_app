import 'package:hive/hive.dart';

part 'task_model.g.dart';

@HiveType(typeId: 5)
class TaskModel extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final String description;
  @HiveField(3)
  final String category;
  @HiveField(4)
  final String priority; // Store as string for Hive
  @HiveField(5)
  final DateTime dueDate;
  @HiveField(6)
  final String time;
  @HiveField(7)
  final bool isCompleted;
  @HiveField(8)
  final List<String> subTasks;
  @HiveField(9)
  final String? endTime;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.dueDate,
    required this.time,
    this.isCompleted = false,
    this.subTasks = const [],
    this.endTime,
  });
}
