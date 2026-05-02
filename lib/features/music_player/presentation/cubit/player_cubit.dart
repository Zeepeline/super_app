import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:super_app/core/services/lyrics_service.dart';
import 'package:super_app/features/music_player/domain/entities/track_entity.dart';
import 'package:super_app/features/music_player/domain/repositories/music_repository.dart';
import 'package:super_app/features/music_player/presentation/cubit/player_state.dart';

class PlayerCubit extends Cubit<PlayerState> {
  final MusicRepository repository;
  final LyricsService lyricsService;
  StreamSubscription? _playbackSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _trackSubscription;

  PlayerCubit({required this.repository, required this.lyricsService})
    : super(PlayerInitial());

  Future<void> setLoading() async {
    emit(PlayerLoading());
  }

  void markCurrentTrackAsDownloaded(String localPath) {
    final currentState = state;
    if (currentState is PlayerLoaded) {
      emit(
        currentState.copyWith(
          track: currentState.track.copyWith(localPath: localPath),
        ),
      );
    }
  }

  Future<void> loadPlayer() async {
    emit(PlayerLoading());

    await repository.initializePlayer();

    final trackResult = await repository.getCurrentTrack();
    final playlistResult = await repository.getCurrentPlaylist();

    trackResult.fold((failure) => emit(PlayerError(failure.message)), (track) {
      playlistResult.fold((failure) => emit(PlayerError(failure.message)), (
        playlist,
      ) {
        emit(
          PlayerLoaded(
            track: track,
            playlist: playlist,
            isShuffle: repository.getShuffleState(),
            isRepeat: repository.getRepeatState(),
          ),
        );
        _setupPlaybackListeners();
        _fetchLyricsForTrack(track);
      });
    });
  }

  void _setupPlaybackListeners() {
    _playbackSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _trackSubscription?.cancel();

    _trackSubscription = repository.currentTrackStream.listen((track) {
      final currentState = state;
      if (currentState is PlayerLoaded && track != null) {
        if (currentState.track.id != track.id) {
          emit(currentState.copyWith(track: track));
          _fetchLyricsForTrack(track);
        }
      }
    });

    _playbackSubscription = repository.isPlayingStream.listen((isPlaying) {
      final currentState = state;
      if (currentState is PlayerLoaded) {
        emit(
          currentState.copyWith(
            track: currentState.track.copyWith(isPlaying: isPlaying),
          ),
        );
      }
    });

    _positionSubscription = repository.positionStream.listen((position) {
      final currentState = state;
      if (currentState is PlayerLoaded) {
        emit(
          currentState.copyWith(
            track: currentState.track.copyWith(currentPosition: position),
          ),
        );
      }
    });

    _durationSubscription = repository.durationStream.listen((duration) {
      final currentState = state;
      if (currentState is PlayerLoaded && duration != null) {
        emit(
          currentState.copyWith(
            track: currentState.track.copyWith(duration: duration),
          ),
        );
      }
    });
  }

  @override
  Future<void> close() {
    _playbackSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _trackSubscription?.cancel();
    return super.close();
  }

  Future<void> play() async {
    final currentState = state;
    if (currentState is PlayerLoaded) {
      await repository.playTrack(currentState.track.id);
      // State is now updated via listeners
    }
  }

  Future<void> selectAndPlay(TrackEntity track) async {
    emit(PlayerLoading());
    final playlistResult = await repository.getCurrentPlaylist();

    playlistResult.fold((failure) => emit(PlayerError(failure.message)), (
      playlist,
    ) async {
      emit(PlayerLoaded(track: track, playlist: playlist));
      _setupPlaybackListeners();
      _fetchLyricsForTrack(track);
      await repository.playTrack(track.id, track: track);
    });
  }

  Future<void> pause() async {
    final currentState = state;
    if (currentState is PlayerLoaded) {
      await repository.pauseTrack();
      // State is now updated via listeners
    }
  }

  Future<void> togglePlayPause() async {
    final currentState = state;
    if (currentState is PlayerLoaded) {
      if (currentState.track.isPlaying) {
        await pause();
      } else {
        await play();
      }
    }
  }

  Future<void> seekTo(Duration position) async {
    final currentState = state;
    if (currentState is PlayerLoaded) {
      final result = await repository.seekTo(position);
      result.fold(
        (failure) => emit(PlayerError(failure.message)),
        (track) => emit(currentState.copyWith(track: track)),
      );
    }
  }

  Future<void> toggleFavorite() async {
    final currentState = state;
    if (currentState is PlayerLoaded) {
      final result = await repository.toggleFavorite(currentState.track.id);
      result.fold(
        (failure) => emit(PlayerError(failure.message)),
        (track) => emit(
          currentState.copyWith(
            track: currentState.track.copyWith(isFavorite: track.isFavorite),
          ),
        ),
      );
    }
  }

  Future<void> skipToNext() async {
    final currentState = state;
    if (currentState is PlayerLoaded) {
      final result = await repository.skipToNext();
      result.fold(
        (failure) => emit(PlayerError(failure.message)),
        (track) => emit(currentState.copyWith(track: track)),
      );
    }
  }

  Future<void> skipToPrevious() async {
    final currentState = state;
    if (currentState is PlayerLoaded) {
      final result = await repository.skipToPrevious();
      result.fold(
        (failure) => emit(PlayerError(failure.message)),
        (track) => emit(currentState.copyWith(track: track)),
      );
    }
  }

  Future<void> toggleShuffle() async {
    final currentState = state;
    if (currentState is PlayerLoaded) {
      final result = await repository.toggleShuffle();
      result.fold(
        (failure) => emit(PlayerError(failure.message)),
        (_) => emit(currentState.copyWith(isShuffle: !currentState.isShuffle)),
      );
    }
  }

  Future<void> toggleRepeat() async {
    final currentState = state;
    if (currentState is PlayerLoaded) {
      final result = await repository.toggleRepeat();
      result.fold(
        (failure) => emit(PlayerError(failure.message)),
        (_) => emit(currentState.copyWith(isRepeat: !currentState.isRepeat)),
      );
    }
  }

  void toggleLyrics() {
    final currentState = state;
    if (currentState is PlayerLoaded) {
      emit(currentState.copyWith(showLyrics: !currentState.showLyrics));
    }
  }

  Future<void> _fetchLyricsForTrack(TrackEntity track) async {
    // Don't fetch if already has lyrics
    if (track.syncedLyrics != null || track.plainLyrics != null) return;

    final result = await lyricsService.fetchLyrics(
      track.artist,
      track.title,
      youtubeId: track.id,
    );
    final synced = result['synced'];
    final plain = result['plain'];

    if (synced != null || plain != null) {
      // PERSIST: Save lyrics to DB so we don't have to fetch them again
      if (track.localPath != null) {
        await repository.saveLyrics(track.localPath!, synced, plain);
      }

      final currentState = state;
      if (currentState is PlayerLoaded && currentState.track.id == track.id) {
        emit(
          currentState.copyWith(
            track: currentState.track.copyWith(
              syncedLyrics: synced,
              plainLyrics: plain,
            ),
          ),
        );
      }
    }
  }
}
