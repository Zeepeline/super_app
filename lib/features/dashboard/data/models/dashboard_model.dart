import 'package:super_app/features/dashboard/domain/entities/dashboard_entity.dart';

class DashboardModel extends DashboardEntity {
  const DashboardModel({
    required super.dailyStatus,
    required super.activeTasks,
    required super.trend,
    required super.insightMessage,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    return DashboardModel(
      dailyStatus: (json['daily_status'] as List)
          .map((e) => StatusModel.fromJson(e))
          .toList(),
      activeTasks: (json['active_tasks'] as List)
          .map((e) => TaskModel.fromJson(e))
          .toList(),
      trend: TrendModel.fromJson(json['trend']),
      insightMessage: json['insight_message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'daily_status': dailyStatus
          .map((e) => (e as StatusModel).toJson())
          .toList(),
      'active_tasks': activeTasks
          .map((e) => (e as TaskModel).toJson())
          .toList(),
      'trend': (trend as TrendModel).toJson(),
      'insight_message': insightMessage,
    };
  }
}

class TaskModel extends TaskEntity {
  const TaskModel({
    required super.id,
    required super.title,
    required super.priority,
    required super.estimatedTime,
    required super.isCompleted,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'],
      title: json['title'],
      priority: json['priority'],
      estimatedTime: json['estimated_time'],
      isCompleted: json['is_completed'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'priority': priority,
      'estimated_time': estimatedTime,
      'is_completed': isCompleted,
    };
  }
}

class StatusModel extends StatusEntity {
  const StatusModel({
    required super.id,
    required super.type,
    required super.title,
    required super.value,
    super.progress,
  });

  factory StatusModel.fromJson(Map<String, dynamic> json) {
    return StatusModel(
      id: json['id'],
      type: json['type'],
      title: json['title'],
      value: json['value'],
      progress: (json['progress'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'value': value,
      'progress': progress,
    };
  }
}

class TrendModel extends TrendEntity {
  const TrendModel({required super.growth, required super.dataPoints});

  factory TrendModel.fromJson(Map<String, dynamic> json) {
    return TrendModel(
      growth: json['growth'],
      dataPoints: (json['data_points'] as List)
          .map((e) => (e as num).toDouble())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'growth': growth, 'data_points': dataPoints};
  }
}
