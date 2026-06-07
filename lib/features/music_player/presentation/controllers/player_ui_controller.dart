import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:get/get.dart';
import 'package:super_app/core/services/media/lyrics_service.dart';
import 'package:super_app/injection_container.dart';
import 'package:super_app/features/music_player/domain/models/lyric_line.dart';
import 'package:super_app/features/music_player/domain/entities/track_entity.dart';
import 'package:super_app/features/music_player/presentation/cubit/player_cubit.dart';
import 'package:super_app/features/music_player/presentation/cubit/player_state.dart';

class PlayerUIController extends GetxController {
  final LyricsService _lyricsService = sl<LyricsService>();

  // Track states mirrored from BLoC for fine-grained reactivity
  final Rxn<TrackEntity> currentTrack = Rxn<TrackEntity>();
  final RxBool isPlaying = false.obs;
  final RxBool showLyrics = false.obs;
  final RxBool isShuffle = false.obs;
  final RxBool isRepeat = false.obs;

  // UI ONLY states
  final RxBool isAlbumArtHovered = false.obs;
  final RxBool isDragging = false.obs;
  final RxDouble dragValue = 0.0.obs;
  final RxList<LyricLine> lyrics = <LyricLine>[].obs;
  final RxString rawLyrics = ''.obs;
  final RxInt activeIndex = (-1).obs;

  StreamSubscription? _blocSubscription;
  StreamSubscription? _positionSubscription;

  // Reactive position stream
  Stream<Duration> get positionStream => AudioService.position;

  void bindCubit(PlayerCubit cubit) {
    _blocSubscription?.cancel();
    _positionSubscription?.cancel();

    // Track active lyric index based on playback position
    _positionSubscription = positionStream.listen((position) {
      if (lyrics.isNotEmpty) {
        final newIndex = _lyricsService.findActiveIndex(lyrics, position);
        if (newIndex != activeIndex.value) {
          activeIndex.value = newIndex;
        }
      }
    });

    _blocSubscription = cubit.stream.listen((state) {
      if (state is PlayerLoading) {
        currentTrack.value = null;
      } else if (state is PlayerLoaded) {
        currentTrack.value = state.track;
        isPlaying.value = state.track.isPlaying;
        showLyrics.value = state.showLyrics;
        isShuffle.value = state.isShuffle;
        isRepeat.value = state.isRepeat;

        // Update lyrics if changed
        if (state.track.syncedLyrics != rawLyrics.value) {
          updateLyrics(state.track.syncedLyrics);
        }
      }
    });

    // Initial state sync
    if (cubit.state is PlayerLoaded) {
      final state = cubit.state as PlayerLoaded;
      currentTrack.value = state.track;
      isPlaying.value = state.track.isPlaying;
      showLyrics.value = state.showLyrics;
      isShuffle.value = state.isShuffle;
      isRepeat.value = state.isRepeat;
      updateLyrics(state.track.syncedLyrics);
    }
  }

  @override
  void onClose() {
    _blocSubscription?.cancel();
    _positionSubscription?.cancel();
    super.onClose();
  }

  void setAlbumArtHover(bool value) => isAlbumArtHovered.value = value;

  void startDragging(double value) {
    isDragging.value = true;
    dragValue.value = value;
  }

  void updateDrag(double value) {
    dragValue.value = value;
  }

  void stopDragging() {
    isDragging.value = false;
  }

  void updateLyrics(String? lrc) {
    if (lrc == null || lrc.isEmpty) {
      if (lyrics.isNotEmpty) lyrics.clear();
      if (rawLyrics.value.isNotEmpty) rawLyrics.value = '';
      return;
    }

    if (rawLyrics.value == lrc) return;

    rawLyrics.value = lrc;
    lyrics.value = _lyricsService.parseLrc(lrc);
    activeIndex.value = -1; // Reset index when lyrics change
  }
}
