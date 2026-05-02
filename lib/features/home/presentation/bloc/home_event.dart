import 'package:equatable/equatable.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object> get props => [];
}

class LoadHomeDataEvent extends HomeEvent {}

class SyncHomeDataEvent extends HomeEvent {}

class DeleteTrackEvent extends HomeEvent {
  final String trackId;

  const DeleteTrackEvent(this.trackId);

  @override
  List<Object> get props => [trackId];
}
