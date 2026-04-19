import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../home/domain/entities/track_entity.dart';
import '../../../home/domain/repositories/home_repository.dart';
import '../../../home/domain/usecases/get_favorite_tracks.dart';

// Events
abstract class LibraryEvent extends Equatable {
  const LibraryEvent();
  @override
  List<Object> get props => [];
}

class LoadFavorites extends LibraryEvent {}

// States
abstract class LibraryState extends Equatable {
  const LibraryState();
  @override
  List<Object> get props => [];
}

class LibraryInitial extends LibraryState {}

class LibraryLoading extends LibraryState {}

class LibraryLoaded extends LibraryState {
  final List<TrackEntity> favoriteTracks;
  const LibraryLoaded({required this.favoriteTracks});
  @override
  List<Object> get props => [favoriteTracks];
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

  LibraryBloc({
    required this.getFavoriteTracks,
    required this.repository,
  }) : super(LibraryInitial()) {
    
    // Listen to repository changes and refresh
    _tracksSubscription = repository.watchTracks().listen((_) {
      add(LoadFavorites());
    });

    on<LoadFavorites>((event, emit) async {
      // Don't show loading on every partial update to avoid flickers
      if (state is LibraryInitial) emit(LibraryLoading());
      
      final result = await getFavoriteTracks(NoParams());
      result.fold(
        (failure) => emit(const LibraryError('Failed to fetch favorites')),
        (tracks) => emit(LibraryLoaded(favoriteTracks: tracks)),
      );
    });
  }

  @override
  Future<void> close() {
    _tracksSubscription?.cancel();
    return super.close();
  }
}
