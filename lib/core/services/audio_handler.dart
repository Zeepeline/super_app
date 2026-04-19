import 'dart:io';
import 'dart:ui';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';

import '../../features/music_player/domain/entities/track_entity.dart';

class AudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  VoidCallback? onSkipNextCallback;
  VoidCallback? onSkipPreviousCallback;

  AudioHandler() {
    _init();
  }

  Future<void> _init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    // Broadcast playback state changes
    _player.playbackEventStream.listen((event) {
      playbackState.add(_transformEvent(event));
    });

    // Handle completions and state changes
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        skipToNext();
      }
      // Trigger a state broadcast on every processing state change
      playbackState.add(_transformEvent(_player.playbackEvent));
    });

    // Handle duration changes dynamically to ensure progress bar works
    _player.durationStream.listen((duration) {
      if (duration != null &&
          mediaItem.value != null &&
          mediaItem.value!.duration != duration) {
        mediaItem.add(mediaItem.value!.copyWith(duration: duration));
      }
    });
  }

  @override
  Future<void> play() async {
    final session = await AudioSession.instance;
    await session.setActive(true);
    await _player.play();
    playbackState.add(_transformEvent(_player.playbackEvent));
  }

  @override
  Future<void> pause() async {
    await _player.pause();
    playbackState.add(_transformEvent(_player.playbackEvent));
  }

  @override
  Future<void> skipToNext() async {
    onSkipNextCallback?.call();
  }

  @override
  Future<void> skipToPrevious() async {
    onSkipPreviousCallback?.call();
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
    playbackState.add(_transformEvent(_player.playbackEvent));
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    final session = await AudioSession.instance;
    await session.setActive(false);
    playbackState.add(_transformEvent(_player.playbackEvent));
  }

  Future<void> setLoopMode(bool enabled) async {
    await _player.setLoopMode(enabled ? LoopMode.one : LoopMode.off);
    playbackState.add(_transformEvent(_player.playbackEvent));
  }

  Future<void> playTrack(TrackEntity track) async {
    try {
      // 1. Activate session first
      final session = await AudioSession.instance;
      await session.setActive(true);

      // 2. Set audio source
      if (track.localPath != null) {
        final file = File(track.localPath!);
        if (await file.exists()) {
          await _player.setAudioSource(AudioSource.file(track.localPath!));
        } else {
          // Fallback if file missing
          await _player.setAudioSource(
            AudioSource.uri(Uri.parse('asset:///${track.localPath}')),
          );
        }
      } else {
        await _player.setUrl(track.audioUrl);
      }

      // 3. Prepare metadata
      final duration = await _player.load() ?? track.duration;

      final item = MediaItem(
        id: track.id,
        album: 'SoundWave',
        title: track.title,
        artist: track.artist,
        duration: duration,
        artUri: Uri.parse(track.albumArtUrl),
      );

      // 4. Update media item
      mediaItem.add(item);

      // 5. Start playback
      await play();
    } catch (e) {
      print("Error playing track: $e");
    }
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: _mapProcessingState(_player.processingState),
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex ?? 0,
    );
  }

  AudioProcessingState _mapProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
      default:
        return AudioProcessingState.idle;
    }
  }

  // Expose streams for UI components
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
}
