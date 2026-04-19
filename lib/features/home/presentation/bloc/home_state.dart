import 'package:equatable/equatable.dart';
import '../../domain/entities/playlist_entity.dart';
import '../../domain/entities/track_entity.dart';

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final List<TrackEntity> popularTracks;
  final List<PlaylistEntity> featuredPlaylists;

  const HomeLoaded({
    required this.popularTracks,
    required this.featuredPlaylists,
  });

  @override
  List<Object> get props => [popularTracks, featuredPlaylists];
}

class HomeError extends HomeState {
  final String message;

  const HomeError(this.message);

  @override
  List<Object> get props => [message];
}
