import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/media_import_service.dart';
import '../../../../core/services/youtube_download_service.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../features/home/data/datasources/home_local_data_source.dart';
import '../../domain/usecases/get_current_user.dart';
import '../../domain/usecases/get_settings.dart';
import '../../domain/usecases/logout.dart';
import '../../domain/usecases/update_audio_quality.dart';
import 'settings_event.dart';
import 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final GetSettings getSettings;
  final GetCurrentUser getCurrentUser;
  final UpdateAudioQuality updateAudioQuality;
  final Logout logout;
  final MediaImportService importService;
  final HomeLocalDataSource homeLocalDataSource;
  final YoutubeDownloadService youtubeDownloadService;

  SettingsBloc({
    required this.getSettings,
    required this.getCurrentUser,
    required this.updateAudioQuality,
    required this.logout,
    required this.importService,
    required this.homeLocalDataSource,
    required this.youtubeDownloadService,
  }) : super(const SettingsInitial()) {
    on<LoadSettingsEvent>(_onLoadSettings);
    on<LoadUserEvent>(_onLoadUser);
    on<UpdateAudioQualityEvent>(_onUpdateAudioQuality);
    on<UpdateDownloadOverCellularEvent>(_onUpdateDownloadOverCellular);
    on<UpdatePushNotificationsEvent>(_onUpdatePushNotifications);
    on<LogoutEvent>(_onLogout);
    on<ScanLocalFoldersEvent>(_onScanLocalFolders);
    on<CloudImportEvent>(_onCloudImport);
    on<LoadBundledMusicEvent>(_onLoadBundledMusic);
    on<DownloadYoutubeTrackEvent>(_onDownloadYoutubeTrack);
    on<SyncDownloadedMusicEvent>(_onSyncDownloadedMusic);
  }

  Future<void> _onCloudImport(
    CloudImportEvent event,
    Emitter<SettingsState> emit,
  ) async {
    // TODO: Implement cloud import functionality
    // This is a placeholder for cloud import (e.g., importing from Google Drive, Dropbox, etc.)
    final currentState = state;
    if (currentState is SettingsLoaded) {
      // Add cloud import logic here
    }
  }

  bool _isImporting = false;

  Future<void> _onScanLocalFolders(
    ScanLocalFoldersEvent event,
    Emitter<SettingsState> emit,
  ) async {
    print("SettingsBloc: ScanLocalFoldersEvent received. _isImporting=$_isImporting, state=${state.runtimeType}");
    
    // Prevent multiple concurrent import operations
    if (_isImporting) {
      print("SettingsBloc: Already importing, ignoring event.");
      return;
    }

    final currentState = state;
    if (currentState is SettingsLoaded) {
      _isImporting = true;
      emit(SettingsImporting(settings: currentState.settings, user: currentState.user));
      print("SettingsBloc: Starting import via MediaImportService...");
      try {
        final tracks = await importService.importLocalTracks();
        print("SettingsBloc: Import returned ${tracks.length} tracks.");
        if (tracks.isNotEmpty) {
          await homeLocalDataSource.addImportedTracks(tracks);
          emit(SettingsImportSuccess(
            settings: currentState.settings,
            user: currentState.user,
            count: tracks.length,
          ));
          // Refresh settings UI
          add(const LoadSettingsEvent());
        } else {
          // User cancelled or no files found — stay on current state
          emit(currentState);
        }
      } catch (e) {
        print("SettingsBloc: Import error: $e");
        emit(SettingsError('Failed to import tracks: ${e.toString()}'));
        // Return to loaded state after error
        add(const LoadSettingsEvent());
      } finally {
        _isImporting = false;
      }
    } else {
      print("SettingsBloc: State is not SettingsLoaded (${state.runtimeType}), ignoring.");
    }
  }

  Future<void> _onLoadSettings(
    LoadSettingsEvent event,
    Emitter<SettingsState> emit,
  ) async {
    emit(const SettingsLoading());

    final settingsResult = await getSettings(NoParams());
    final userResult = await getCurrentUser(NoParams());

    settingsResult.fold((failure) => emit(SettingsError(failure.message)), (
      settings,
    ) {
      userResult.fold(
        (failure) => emit(SettingsLoaded(settings: settings)),
        (user) => emit(SettingsLoaded(settings: settings, user: user)),
      );
    });
  }

  Future<void> _onLoadUser(
    LoadUserEvent event,
    Emitter<SettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is SettingsLoaded) {
      final result = await getCurrentUser(NoParams());
      result.fold(
        (failure) => emit(currentState),
        (user) => emit(currentState.copyWith(user: user)),
      );
    }
  }

  Future<void> _onUpdateAudioQuality(
    UpdateAudioQualityEvent event,
    Emitter<SettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is SettingsLoaded) {
      final result = await updateAudioQuality(event.quality);
      result.fold(
        (failure) => emit(SettingsError(failure.message)),
        (settings) => emit(currentState.copyWith(settings: settings)),
      );
    }
  }

  Future<void> _onUpdateDownloadOverCellular(
    UpdateDownloadOverCellularEvent event,
    Emitter<SettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is SettingsLoaded) {
      final newSettings = currentState.settings.copyWith(
        downloadOverCellular: event.value,
      );
      // Emit immediately for UI responsiveness, actual save would be async
      emit(currentState.copyWith(settings: newSettings));
    }
  }

  Future<void> _onUpdatePushNotifications(
    UpdatePushNotificationsEvent event,
    Emitter<SettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is SettingsLoaded) {
      final newSettings = currentState.settings.copyWith(
        pushNotifications: event.value,
      );
      // Emit immediately for UI responsiveness, actual save would be async
      emit(currentState.copyWith(settings: newSettings));
    }
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<SettingsState> emit) async {
    emit(const SettingsLoading());
    final result = await logout(NoParams());
    result.fold(
      (failure) => emit(SettingsError(failure.message)),
      (_) => emit(const LogoutSuccess()),
    );
  }

  Future<void> _onLoadBundledMusic(
    LoadBundledMusicEvent event,
    Emitter<SettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is SettingsLoaded) {
      try {
        final tracks = await importService.loadBundledAssets();
        if (tracks.isNotEmpty) {
          await homeLocalDataSource.addImportedTracks(tracks);
          emit(SettingsImportSuccess(
            settings: currentState.settings,
            user: currentState.user,
            count: tracks.length,
          ));
          add(const LoadSettingsEvent());
        } else {
          emit(currentState);
        }
      } catch (e) {
        print("SettingsBloc: Error loading bundled music: $e");
        emit(currentState);
      }
    }
  }

  Future<void> _onDownloadYoutubeTrack(
    DownloadYoutubeTrackEvent event,
    Emitter<SettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is SettingsLoaded) {
      try {
        final track = await youtubeDownloadService.downloadAndConvert(
          url: event.url,
          onProgress: (stage, progress) {
            emit(SettingsDownloadingYoutube(
            settings: currentState.settings,
            user: currentState.user,
            stage: stage,
            progress: progress,
          ));
          },
        );

        if (track != null) {
          await homeLocalDataSource.addImportedTracks([track]);
          emit(SettingsDownloadSuccess(
            settings: currentState.settings,
            user: currentState.user,
            title: track.title,
          ));
          // Refresh settings UI
          add(const LoadSettingsEvent());
        } else {
          emit(const SettingsError('Failed to download YouTube track.'));
          emit(currentState);
        }
      } catch (e) {
        emit(SettingsError('Download error: ${e.toString()}'));
        emit(currentState);
      }
    }
  }

  Future<void> _onSyncDownloadedMusic(
    SyncDownloadedMusicEvent event,
    Emitter<SettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is SettingsLoaded) {
      _isImporting = true;
      emit(SettingsImporting(settings: currentState.settings, user: currentState.user));
      try {
        final tracks = await importService.scanDownloadedMusic();
        if (tracks.isNotEmpty) {
          await homeLocalDataSource.addImportedTracks(tracks);
          emit(SettingsImportSuccess(
            settings: currentState.settings,
            user: currentState.user,
            count: tracks.length,
          ));
          add(const LoadSettingsEvent());
        } else {
          emit(currentState);
        }
      } catch (e) {
        print("SettingsBloc: Sync error: $e");
        emit(SettingsError('Failed to sync downloads: ${e.toString()}'));
        add(const LoadSettingsEvent());
      } finally {
        _isImporting = false;
      }
    }
  }
}
