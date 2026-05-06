import 'package:equatable/equatable.dart';
import '../../domain/entities/dashboard_entity.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();
  
  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final DashboardEntity dashboardData;

  const DashboardLoaded({required this.dashboardData});

  @override
  List<Object?> get props => [dashboardData];
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError({required this.message});

  @override
  List<Object?> get props => [message];
}
