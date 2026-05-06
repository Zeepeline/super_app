import 'package:equatable/equatable.dart';

class TaskEntity extends Equatable {
  final String id;
  final String title;
  final String priority; // 'high', 'medium', 'low'
  final String estimatedTime;
  final bool isCompleted;

  const TaskEntity({
    required this.id,
    required this.title,
    required this.priority,
    required this.estimatedTime,
    required this.isCompleted,
  });

  @override
  List<Object?> get props => [id, title, priority, estimatedTime, isCompleted];
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

  const TrendEntity({
    required this.growth,
    required this.dataPoints,
  });

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
