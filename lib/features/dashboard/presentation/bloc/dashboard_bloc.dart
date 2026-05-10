import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/get_dashboard_data.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final GetDashboardData getDashboardData;

  DashboardBloc({required this.getDashboardData}) : super(DashboardInitial()) {
    on<LoadDashboardDataEvent>((event, emit) async {
      emit(DashboardLoading());

      final result = await getDashboardData(NoParams());

      result.fold(
        (failure) => emit(DashboardError(message: failure.message)),
        (data) => emit(DashboardLoaded(dashboardData: data)),
      );
    });
  }
}
