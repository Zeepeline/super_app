import 'package:dartz/dartz.dart';
import 'package:super_app/features/tasks/domain/repositories/task_repository.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/session_entity.dart';
import '../../domain/repositories/schedule_repository.dart';
import '../datasources/schedule_remote_datasource.dart';

class ScheduleRepositoryImpl implements ScheduleRepository {
  final ScheduleRemoteDataSource remoteDataSource;
  final TaskRepository taskRepository;

  ScheduleRepositoryImpl({
    required this.remoteDataSource,
    required this.taskRepository,
  });

  @override
  Future<Either<Failure, List<SessionEntity>>> getSessionsByDate(DateTime date) async {
    try {
      // Fetch remote sessions (dummy/external)
      final remoteSessions = await remoteDataSource.getSessionsByDate(date);

      // Fetch real tasks from TaskRepository
      final tasksResult = await taskRepository.getTasks();

      return tasksResult.fold(
        (failure) => Right(remoteSessions), // If tasks fail, still show remote sessions
        (realTasks) {
          final now = DateTime.now();
          final isToday = now.year == date.year &&
              now.month == date.month &&
              now.day == date.day;

          // Filter tasks for the selected date
          final dateTasks = realTasks.where((task) {
            return task.dueDate.year == date.year &&
                task.dueDate.month == date.month &&
                task.dueDate.day == date.day;
          }).toList();

          // Map tasks to SessionEntity with dynamic isLive status
          final taskSessions = dateTasks.map((t) {
            bool isLive = false;
            
            if (isToday) {
              try {
                // Parse start time (expecting HH:mm)
                final startParts = t.time.split(':');
                if (startParts.length == 2) {
                  final startHour = int.parse(startParts[0]);
                  final startMinute = int.parse(startParts[1]);
                  final startTime = DateTime(now.year, now.month, now.day, startHour, startMinute);
                  
                  DateTime endTime;
                  if (t.endTime != null) {
                    final endParts = t.endTime!.split(':');
                    if (endParts.length == 2) {
                      endTime = DateTime(now.year, now.month, now.day, int.parse(endParts[0]), int.parse(endParts[1]));
                    } else {
                      endTime = startTime.add(const Duration(hours: 1));
                    }
                  } else {
                    endTime = startTime.add(const Duration(hours: 1));
                  }
                  
                  if (now.isAfter(startTime) && now.isBefore(endTime)) {
                    isLive = true;
                  }
                }
              } catch (_) {
                // Ignore parsing errors
              }
            }

            String timeDisplay = t.time;
            if (t.endTime != null) {
              timeDisplay = "${t.time} - ${t.endTime}";
            }

            return SessionEntity(
              id: t.id,
              time: timeDisplay,
              title: t.title,
              description: t.description,
              tag: isLive ? 'LIVE NOW' : t.category,
              participants: const [],
              isLive: isLive,
            );
          }).toList();

          // Combine both
          final combined = [...remoteSessions, ...taskSessions];
          
          // Sort by time (assuming time is HH:mm format)
          combined.sort((a, b) => a.time.compareTo(b.time));

          return Right(combined);
        },
      );
    } on ServerException {
      return const Left(ServerFailure('Failed to load schedule from server'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
