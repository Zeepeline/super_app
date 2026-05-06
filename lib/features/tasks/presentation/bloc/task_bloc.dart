import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/usecases/add_task.dart';

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
  final List<String> subTasks;

  const AddTaskEvent({
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.dueDate,
    required this.time,
    required this.subTasks,
  });

  @override
  List<Object?> get props => [title, description, category, priority, dueDate, time, subTasks];
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
class TaskError extends TaskState {
  final String message;
  const TaskError(this.message);
  @override
  List<Object?> get props => [message];
}

// Bloc
class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final AddTask addTask;

  TaskBloc({required this.addTask}) : super(TaskInitial()) {
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
        subTasks: event.subTasks,
      );

      final result = await addTask(task);
      
      result.fold(
        (failure) => emit(TaskError(failure.message)),
        (_) => emit(TaskSuccess()),
      );
    });
  }
}
