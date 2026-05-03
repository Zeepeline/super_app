import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/media_import_service.dart';
import '../../../../core/usecases/usecase.dart';
import '../../data/datasources/home_local_data_source.dart';
import '../../domain/usecases/get_featured_playlists.dart';
import '../../domain/usecases/get_popular_tracks.dart';
import '../../domain/usecases/delete_track.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final GetPopularTracks getPopularTracks;
  final GetFeaturedPlaylists getFeaturedPlaylists;
  final MediaImportService mediaImportService;
  final HomeLocalDataSource localDataSource;

  final DeleteTrackUseCase deleteTrackUseCase;

  HomeBloc({
    required this.getPopularTracks,
    required this.getFeaturedPlaylists,
    required this.mediaImportService,
    required this.localDataSource,
    required this.deleteTrackUseCase,
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

          // 2. Trigger background sync after a delay to keep UI responsive on startup
          Future.delayed(const Duration(seconds: 3), () {
            if (!isClosed) {
              add(SyncHomeDataEvent());
            }
          });
        });
      });
    });

    on<SyncHomeDataEvent>((event, emit) async {
      // AUTO-SYNC: Sync local downloads folder in the background
      try {
        // 1. Scan for actual files on disk (this gets new correct paths on iOS)
        // Pass existing paths to skip re-processing files we already have
        // But wait, if paths changed, scanDownloadedMusic will find them as "new".
        // That's fine because addImportedTracks will update them by ID.
        final localTracks = await mediaImportService.scanDownloadedMusic();

        // 3. Update database with discovered tracks (updates paths for existing IDs)
        if (localTracks.isNotEmpty) {
          await localDataSource.addImportedTracks(localTracks);
        }

        // 4. MIGRATION: Fix existing tracks that have "0:00" duration or old format
        bool migrated = false;
        // Re-fetch since we just updated paths
        final refreshedTracks = await localDataSource.getPopularTracks();

        for (final track in refreshedTracks) {
          String currentDuration = track.duration;
          bool needsFix = false;
          String? fixedDuration;

          // 4a. Fix "0:00" or empty duration
          if (currentDuration == "0:00" || currentDuration.isEmpty) {
            needsFix = true;
          }
          // 4b. Fix long duration format "H:MM:SS.ms" to "M:SS"
          else if (currentDuration.contains('.') ||
              currentDuration.split(':').length > 2) {
            try {
              final parts = currentDuration.split('.');
              final timeParts = parts[0].split(':');
              if (timeParts.length >= 2) {
                final min = int.parse(timeParts[timeParts.length - 2]);
                final sec = int.parse(timeParts[timeParts.length - 1]);
                fixedDuration = "$min:${sec.toString().padLeft(2, '0')}";
                needsFix = true;
              }
            } catch (_) {}
          }

          if (needsFix &&
              track.localPath != null &&
              track.localPath!.isNotEmpty) {
            try {
              // Only fix if the file actually exists (AudioHandler handles path resolution,
              // but for duration extraction we need a valid path here)
              final file = File(track.localPath!);
              if (await file.exists()) {
                final newDuration =
                    fixedDuration ??
                    await mediaImportService.getAudioDurationText(
                      track.localPath!,
                    );
                if (newDuration != "0:00") {
                  await localDataSource.updateTrackDuration(
                    track.localPath!,
                    newDuration,
                  );
                  migrated = true;
                }
              }
            } catch (e) {
              print(
                "HomeBloc: Failed to migrate duration for ${track.title}: $e",
              );
            }
          }
        }

        if (localTracks.isNotEmpty || migrated) {
          // Reload UI with updated data
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
      } catch (e) {}
    });
    on<DeleteTrackEvent>((event, emit) async {
      try {
        final result = await deleteTrackUseCase(event.trackId);
        result.fold((failure) => emit(HomeError(failure.message)), (_) {
          // Refresh list after deletion
          add(LoadHomeDataEvent());
        });
      } catch (e) {
        emit(HomeError("Failed to delete track: $e"));
      }
    });
  }
}
