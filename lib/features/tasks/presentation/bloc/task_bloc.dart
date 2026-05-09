import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/usecases/add_task.dart';
import '../../domain/usecases/update_task.dart';
import '../../domain/usecases/delete_task.dart';

// Events
abstract class TaskEvent extends Equatable {
  const TaskEvent();
  @override
  List<Object?> get props => [];
}

class AddTaskEvent extends TaskEvent {
  final String title;
  final String description;
  final String category;
  final TaskPriority priority;
  final DateTime dueDate;
  final String time;
  final String? endTime;
  final List<String> subTasks;

  const AddTaskEvent({
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.dueDate,
    required this.time,
    this.endTime,
    required this.subTasks,
  });

  @override
  List<Object?> get props => [title, description, category, priority, dueDate, time, endTime, subTasks];
}

class UpdateTaskStatusEvent extends TaskEvent {
  final TaskEntity task;
  final bool isCompleted;

  const UpdateTaskStatusEvent({
    required this.task,
    required this.isCompleted,
  });

  @override
  List<Object?> get props => [task, isCompleted];
}

class UpdateTaskEvent extends TaskEvent {
  final TaskEntity task;
  const UpdateTaskEvent({required this.task});

  @override
  List<Object?> get props => [task];
}

class DeleteTaskEvent extends TaskEvent {
  final String id;
  const DeleteTaskEvent(this.id);
  @override
  List<Object?> get props => [id];
}

// States
abstract class TaskState extends Equatable {
  const TaskState();
  @override
  List<Object?> get props => [];
}

class TaskInitial extends TaskState {}
class TaskLoading extends TaskState {}
class TaskSuccess extends TaskState {}
class TaskDeleted extends TaskState {}
class TaskError extends TaskState {
  final String message;
  const TaskError(this.message);
  @override
  List<Object?> get props => [message];
}

// Bloc
class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final AddTask addTask;
  final UpdateTask updateTask;
  final DeleteTask deleteTask;

  TaskBloc({
    required this.addTask,
    required this.updateTask,
    required this.deleteTask,
  }) : super(TaskInitial()) {
    on<AddTaskEvent>((event, emit) async {
      emit(TaskLoading());
      
      final task = TaskEntity(
        id: const Uuid().v4(),
        title: event.title,
        description: event.description,
        category: event.category,
        priority: event.priority,
        dueDate: event.dueDate,
        time: event.time,
        endTime: event.endTime,
        subTasks: event.subTasks,
      );

      final result = await addTask(task);
      
      result.fold(
        (failure) => emit(TaskError(failure.message)),
        (_) => emit(TaskSuccess()),
      );
    });

    on<UpdateTaskStatusEvent>((event, emit) async {
      emit(TaskLoading());
      
      final updatedTask = event.task.copyWith(isCompleted: event.isCompleted);

      final result = await updateTask(updatedTask);
      
      result.fold(
        (failure) => emit(TaskError(failure.message)),
        (_) => emit(TaskSuccess()),
      );
    });

    on<UpdateTaskEvent>((event, emit) async {
      emit(TaskLoading());
      
      final result = await updateTask(event.task);
      
      result.fold(
        (failure) => emit(TaskError(failure.message)),
        (_) => emit(TaskSuccess()),
      );
    });

    on<DeleteTaskEvent>((event, emit) async {
      emit(TaskLoading());
      final result = await deleteTask(event.id);
      result.fold(
        (failure) => emit(TaskError(failure.message)),
        (_) => emit(TaskDeleted()),
      );
    });
  }
}
