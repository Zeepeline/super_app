import "package:flutter/foundation.dart";
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/media_import_service.dart';
import '../../../../core/usecases/usecase.dart';
import '../../data/datasources/home_local_data_source.dart';
import '../../domain/usecases/get_featured_playlists.dart';
import '../../domain/usecases/get_popular_tracks.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final GetPopularTracks getPopularTracks;
  final GetFeaturedPlaylists getFeaturedPlaylists;
  final MediaImportService mediaImportService;
  final HomeLocalDataSource localDataSource;

  HomeBloc({
    required this.getPopularTracks,
    required this.getFeaturedPlaylists,
    required this.mediaImportService,
    required this.localDataSource,
  }) : super(HomeInitial()) {
    on<LoadHomeDataEvent>((event, emit) async {
      emit(HomeLoading());

      // 1. Load cached data instantly
      final tracksEither = await getPopularTracks(NoParams());
      final playlistsEither = await getFeaturedPlaylists(NoParams());

      tracksEither.fold((failure) => emit(HomeError(failure.message)), (
        tracks,
      ) {
        playlistsEither.fold((failure) => emit(HomeError(failure.message)), (
          playlists,
        ) {
          emit(HomeLoaded(popularTracks: tracks, featuredPlaylists: playlists));

          // 2. Trigger background sync after UI is loaded
          add(SyncHomeDataEvent());
        });
      });
    });

    on<SyncHomeDataEvent>((event, emit) async {
      // AUTO-SYNC: Sync local downloads folder in the background
      try {
        debugPrint("HomeBloc: Starting background sync...");
        // Get existing paths to avoid redundant lyric fetching
        final existingTracks = await localDataSource.getPopularTracks();
        final existingPaths = existingTracks
            .map((t) => t.localPath)
            .whereType<String>()
            .toSet();

        final localTracks = await mediaImportService.scanDownloadedMusic(
          existingPaths: existingPaths,
        );

        // MIGRATION: Fix existing tracks that have "0:00" duration
        bool migrated = false;
        for (final track in existingTracks) {
          if ((track.duration == "0:00" || track.duration.isEmpty) &&
              track.localPath != null &&
              track.localPath!.isNotEmpty) {
            try {
              final newDuration = await mediaImportService.getAudioDurationText(
                track.localPath!,
              );
              if (newDuration != "0:00") {
                await localDataSource.updateTrackDuration(
                  track.localPath!,
                  newDuration,
                );
                migrated = true;
                debugPrint(
                  "HomeBloc: Fixed duration for ${track.title} -> $newDuration",
                );
              }
            } catch (e) {
              debugPrint(
                "HomeBloc: Failed to migrate duration for ${track.title}: $e",
              );
            }
          }
        }

        if (localTracks.isNotEmpty || migrated) {
          if (localTracks.isNotEmpty) {
            await localDataSource.addImportedTracks(localTracks);
          }

          // If new tracks were added OR existing tracks were updated, reload the UI
          final updatedTracksEither = await getPopularTracks(NoParams());
          updatedTracksEither.fold((_) => null, (tracks) {
            if (state is HomeLoaded) {
              final currentState = state as HomeLoaded;
              emit(
                HomeLoaded(
                  popularTracks: tracks,
                  featuredPlaylists: currentState.featuredPlaylists,
                ),
              );
            }
          });
        }
        debugPrint("HomeBloc: Background sync completed.");
      } catch (e) {
        debugPrint("Auto-Sync Error: $e");
      }
    });
  }
}
