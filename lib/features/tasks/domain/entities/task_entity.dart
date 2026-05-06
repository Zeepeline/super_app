import 'package:equatable/equatable.dart';

enum TaskPriority { low, medium, high }

class TaskEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final String category;
  final TaskPriority priority;
  final DateTime dueDate;
  final String time;
  final bool isCompleted;
  final List<String> subTasks;

  const TaskEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.dueDate,
    required this.time,
    this.isCompleted = false,
    this.subTasks = const [],
  });

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        category,
        priority,
        dueDate,
        time,
        isCompleted,
        subTasks,
      ];
}
