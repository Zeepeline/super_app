import 'package:hive/hive.dart';
import '../../../../core/utils/hive_box_constants.dart';
import '../../domain/entities/task_entity.dart';

part 'task_model.g.dart';

// ignore: must_be_immutable
@HiveType(typeId: HiveBoxConstants.taskTypeId)
class TaskModel extends TaskEntity {
  @HiveField(0)
  @override
  // ignore: overridden_fields
  final String id;

  @HiveField(1)
  @override
  // ignore: overridden_fields
  final String title;

  @HiveField(2)
  @override
  // ignore: overridden_fields
  final String description;

  @HiveField(3)
  @override
  // ignore: overridden_fields
  final String category;

  @HiveField(4)
  final int priorityIndex;

  @HiveField(5)
  @override
  // ignore: overridden_fields
  final DateTime dueDate;

  @HiveField(6)
  @override
  // ignore: overridden_fields
  final String time;

  @HiveField(7)
  @override
  // ignore: overridden_fields
  final bool isCompleted;

  @HiveField(8)
  @override
  // ignore: overridden_fields
  final List<String> subTasks;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.priorityIndex,
    required this.dueDate,
    required this.time,
    required this.isCompleted,
    required this.subTasks,
  }) : super(
          id: id,
          title: title,
          description: description,
          category: category,
          priority: TaskPriority.values[priorityIndex],
          dueDate: dueDate,
          time: time,
          isCompleted: isCompleted,
          subTasks: subTasks,
        );

  @override
  TaskPriority get priority => TaskPriority.values[priorityIndex];

  factory TaskModel.fromEntity(TaskEntity task) {
    return TaskModel(
      id: task.id,
      title: task.title,
      description: task.description,
      category: task.category,
      priorityIndex: task.priority.index,
      dueDate: task.dueDate,
      time: task.time,
      isCompleted: task.isCompleted,
      subTasks: task.subTasks,
    );
  }

  TaskEntity toEntity() {
    return TaskEntity(
      id: id,
      title: title,
      description: description,
      category: category,
      priority: priority,
      dueDate: dueDate,
      time: time,
      isCompleted: isCompleted,
      subTasks: subTasks,
    );
  }
}
