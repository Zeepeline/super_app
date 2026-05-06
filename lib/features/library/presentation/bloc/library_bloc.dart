import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../home/domain/entities/track_entity.dart';
import '../../../home/domain/repositories/home_repository.dart';
import '../../../home/domain/usecases/get_favorite_tracks.dart';

// Categories
enum LibraryCategory { playlists, artists, albums }

// Events
abstract class LibraryEvent extends Equatable {
  const LibraryEvent();
  @override
  List<Object> get props => [];
}

class LoadFavorites extends LibraryEvent {}

class ChangeCategory extends LibraryEvent {
  final LibraryCategory category;
  const ChangeCategory(this.category);
  @override
  List<Object> get props => [category];
}

// States
abstract class LibraryState extends Equatable {
  const LibraryState();
  @override
  List<Object> get props => [];
}

class LibraryInitial extends LibraryState {}

class LibraryLoading extends LibraryState {}

class LibraryLoaded extends LibraryState {
  final List<TrackEntity> tracks;
  final LibraryCategory selectedCategory;

  const LibraryLoaded({
    required this.tracks,
    this.selectedCategory = LibraryCategory.playlists,
  });

  @override
  List<Object> get props => [tracks, selectedCategory];
}

class LibraryError extends LibraryState {
  final String message;
  const LibraryError(this.message);
  @override
  List<Object> get props => [message];
}

// BLoC
class LibraryBloc extends Bloc<LibraryEvent, LibraryState> {
  final GetFavoriteTracks getFavoriteTracks;
  final HomeRepository repository;
  StreamSubscription? _tracksSubscription;

  LibraryBloc({required this.getFavoriteTracks, required this.repository})
    : super(LibraryInitial()) {
    // Listen to repository changes and refresh
    _tracksSubscription = repository.watchTracks().listen((_) {
      add(LoadFavorites());
    });

    on<LoadFavorites>((event, emit) async {
      // Don't show loading on every partial update to avoid flickers
      if (state is LibraryInitial) emit(LibraryLoading());

      final result = await repository.getPopularTracks();
      result.fold(
        (failure) => emit(const LibraryError('Failed to fetch tracks')),
        (tracks) {
          final currentCategory = state is LibraryLoaded
              ? (state as LibraryLoaded).selectedCategory
              : LibraryCategory.playlists;
          emit(
            LibraryLoaded(tracks: tracks, selectedCategory: currentCategory),
          );
        },
      );
    });

    on<ChangeCategory>((event, emit) {
      if (state is LibraryLoaded) {
        final currentState = state as LibraryLoaded;
        emit(
          LibraryLoaded(
            tracks: currentState.tracks,
            selectedCategory: event.category,
          ),
        );
      }
    });
  }

  @override
  Future<void> close() {
    _tracksSubscription?.cancel();
    return super.close();
  }
}
