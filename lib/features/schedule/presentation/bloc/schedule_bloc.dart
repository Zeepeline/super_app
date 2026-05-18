import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/session_entity.dart';
import '../../domain/usecases/get_sessions.dart';
import '../../../holidays/domain/entities/holiday_entity.dart';
import '../../../holidays/domain/usecases/get_holidays.dart';

// Events
abstract class ScheduleEvent extends Equatable {
  const ScheduleEvent();
  @override
  List<Object> get props => [];
}

class LoadScheduleEvent extends ScheduleEvent {
  final DateTime date;
  const LoadScheduleEvent(this.date);
  @override
  List<Object> get props => [date];
}

// States
abstract class ScheduleState extends Equatable {
  final DateTime selectedDate;
  final List<HolidayEntity> holidays;

  const ScheduleState({required this.selectedDate, required this.holidays});

  @override
  List<Object> get props => [selectedDate, holidays];

  HolidayEntity? getHolidayForDate(DateTime date) {
    try {
      return holidays.firstWhere(
        (h) =>
            h.date.year == date.year &&
            h.date.month == date.month &&
            h.date.day == date.day,
      );
    } catch (_) {
      return null;
    }
  }
}

class ScheduleInitial extends ScheduleState {
  ScheduleInitial() : super(selectedDate: DateTime.now(), holidays: const []);
}

class ScheduleLoading extends ScheduleState {
  const ScheduleLoading({
    required DateTime selectedDate,
    required List<HolidayEntity> holidays,
  }) : super(selectedDate: selectedDate, holidays: holidays);
}

class ScheduleLoaded extends ScheduleState {
  final List<SessionEntity> sessions;

  const ScheduleLoaded({
    required this.sessions,
    required List<HolidayEntity> holidays,
    required DateTime selectedDate,
  }) : super(selectedDate: selectedDate, holidays: holidays);

  @override
  List<Object> get props => [sessions, holidays, selectedDate];
}

class ScheduleError extends ScheduleState {
  final String message;
  const ScheduleError({
    required this.message,
    required DateTime selectedDate,
    required List<HolidayEntity> holidays,
  }) : super(selectedDate: selectedDate, holidays: holidays);

  @override
  List<Object> get props => [message, selectedDate, holidays];
}

// Bloc
class ScheduleBloc extends Bloc<ScheduleEvent, ScheduleState> {
  final GetSessions getSessions;
  final GetHolidays getHolidays;

  List<HolidayEntity> _cachedHolidays = [];
  int? _cachedYear;

  ScheduleBloc({required this.getSessions, required this.getHolidays})
    : super(ScheduleInitial()) {
    on<LoadScheduleEvent>((event, emit) async {
      emit(
        ScheduleLoading(selectedDate: event.date, holidays: _cachedHolidays),
      );

      if (_cachedYear != event.date.year) {
        final holidayResult = await getHolidays(event.date.year);
        holidayResult.fold((failure) => null, (holidays) {
          _cachedHolidays = holidays;
          _cachedYear = event.date.year;
        });
      }

      final sessionResult = await getSessions(event.date);
      sessionResult.fold(
        (failure) => emit(
          ScheduleError(
            message: failure.message,
            selectedDate: event.date,
            holidays: _cachedHolidays,
          ),
        ),
        (sessions) => emit(
          ScheduleLoaded(
            sessions: sessions,
            holidays: _cachedHolidays,
            selectedDate: event.date,
          ),
        ),
      );
    });
  }
}
