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
    required super.description,
    required super.category,
    required super.priority,
    required super.dueDate,
    required super.time,
    required super.isCompleted,
    required super.subTasks,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      category: json['category'] ?? 'Work',
      priority: _parsePriority(json['priority']),
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'])
          : DateTime.now(),
      time: json['time'] ?? '00:00',
      isCompleted: json['is_completed'] ?? false,
      subTasks: json['sub_tasks'] != null
          ? List<String>.from(json['sub_tasks'])
          : [],
    );
  }

  static TaskPriority _parsePriority(dynamic priority) {
    if (priority is String) {
      switch (priority.toLowerCase()) {
        case 'high':
          return TaskPriority.high;
        case 'low':
          return TaskPriority.low;
        default:
          return TaskPriority.medium;
      }
    }
    return TaskPriority.medium;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'priority': priority.toString().split('.').last,
      'due_date': dueDate.toIso8601String(),
      'time': time,
      'is_completed': isCompleted,
      'sub_tasks': subTasks,
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
