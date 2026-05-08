import 'package:equatable/equatable.dart';
import 'package:super_app/features/tasks/domain/entities/task_entity.dart'
    as real_task;

// Re-export or use the same structure
typedef TaskPriority = real_task.TaskPriority;

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
    required this.isCompleted,
    required this.subTasks,
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

class StatusEntity extends Equatable {
  final String id;
  final String type; // 'next_up', 'meeting', 'readiness'
  final String title;
  final String value;
  final double? progress; // For readiness

  const StatusEntity({
    required this.id,
    required this.type,
    required this.title,
    required this.value,
    this.progress,
  });

  @override
  List<Object?> get props => [id, type, title, value, progress];
}

class TrendEntity extends Equatable {
  final String growth;
  final List<double> dataPoints;

  const TrendEntity({required this.growth, required this.dataPoints});

  @override
  List<Object?> get props => [growth, dataPoints];
}

class DashboardEntity extends Equatable {
  final List<StatusEntity> dailyStatus;
  final List<TaskEntity> activeTasks;
  final TrendEntity trend;
  final String insightMessage;

  const DashboardEntity({
    required this.dailyStatus,
    required this.activeTasks,
    required this.trend,
    required this.insightMessage,
  });

  @override
  List<Object?> get props => [dailyStatus, activeTasks, trend, insightMessage];
}
