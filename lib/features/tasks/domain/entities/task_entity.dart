import 'package:equatable/equatable.dart';

enum TaskPriority { high, medium, low }

class TaskEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final String category;
  final TaskPriority priority;
  final DateTime dueDate;
  final String time; // Start time (HH:mm)
  final String? endTime; // End time (HH:mm)
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
    this.endTime,
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
    endTime,
    isCompleted,
    subTasks,
  ];
}
