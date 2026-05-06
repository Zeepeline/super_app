import 'dart:developer' as dev;
import 'dart:io';
import 'dart:ui';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:super_app/features/music_player/domain/entities/track_entity.dart';

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
        dev.log("AudioHandler: ProcessingState.completed reached. Skipping...");
        skipToNext();
      }
      playbackState.add(_transformEvent(_player.playbackEvent));
    });

    // WATCHDOG: For streaming tracks, sometimes 'completed' state is never reached.
    // We check if position is >= duration - 500ms to trigger next track.
    _player.positionStream.listen((position) {
      final duration = _player.duration;
      if (duration != null && duration > Duration.zero) {
        // If we are within 1 second of the end and still playing/buffering
        if (position >= duration - const Duration(milliseconds: 1000)) {
          if (_player.processingState != ProcessingState.completed &&
              _player.playing) {
            dev.log(
              "AudioHandler: Watchdog detected end of stream. Forcing next...",
            );
            // Pause first to prevent multiple triggers
            _player.pause();
            skipToNext();
          }
        }
      }
    });

    // Handle duration changes dynamically to ensure progress bar works,
    // but PREFER the original metadata duration if it is valid.
    // This prevents just_audio from reporting artificially long durations for HTTP streams.
    _player.durationStream.listen((duration) {
      final currentItem = mediaItem.value;
      if (duration != null && currentItem != null) {
        if (currentItem.duration == null ||
            currentItem.duration == Duration.zero) {
          mediaItem.add(currentItem.copyWith(duration: duration));
        }
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

  /// Resolves absolute paths that might have changed (common on iOS Sandbox)
  Future<String?> _resolvePath(String? path) async {
    if (path == null || path.isEmpty) return null;

    final file = File(path);
    if (await file.exists()) return path;

    // Handle iOS Sandbox UUID rotation
    if (Platform.isIOS && path.contains('/Documents/')) {
      try {
        final appDir = await getApplicationDocumentsDirectory();
        // Extract relative path after 'Documents/'
        final parts = path.split('/Documents/');
        if (parts.length > 1) {
          final relativePath = parts.last;
          final newPath = p.join(appDir.path, relativePath);
          if (await File(newPath).exists()) {
            return newPath;
          }
        }
      } catch (e) {}
    }

    return null;
  }

  Future<void> playTrack(TrackEntity track) async {
    try {
      // 1. Reset player to ensure clean transition in background
      await _player.stop();

      // 2. Activate session
      final session = await AudioSession.instance;
      await session.setActive(true);

      // 3. Resolve source with fallback
      AudioSource? source;
      final resolvedLocalPath = await _resolvePath(track.localPath);

      if (resolvedLocalPath != null && await File(resolvedLocalPath).exists()) {
        dev.log("AudioHandler: Playing from local file: $resolvedLocalPath");
        source = AudioSource.file(resolvedLocalPath);
      } else if (track.audioUrl.isNotEmpty) {
        dev.log(
          "AudioHandler: Local file missing or invalid, falling back to streaming",
        );
        dev.log(
          "AudioHandler: Using LockCachingAudioSource for stable streaming",
        );

        source = LockCachingAudioSource(
          Uri.parse(track.audioUrl),
          headers: {
            'User-Agent':
                'Mozilla/5.0 (iPhone; CPU iPhone OS 17_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4.1 Mobile/15E148 Safari/604.1',
            'Referer': 'https://www.youtube.com/',
            'Origin': 'https://www.youtube.com',
          },
        );
      }

      if (source == null) {
        // Last resort: If it's a YouTube ID, we might need one more refresh attempt
        // but for now we throw to trigger the Repository's retry logic
        throw Exception(
          "No valid audio source (local or stream) for: ${track.title}",
        );
      }

      // 4. Set source and start playing
      await _player.setAudioSource(source);

      // 5. Prepare metadata
      final item = MediaItem(
        id: track.id,
        album: track.album,
        title: track.title,
        artist: track.artist,
        duration: track.duration, // Use existing duration initially
        artUri: Uri.parse(track.albumArtUrl),
      );
      mediaItem.add(item);

      // 6. Start playback
      await play();
    } catch (e) {
      dev.log("AudioHandler: Error playing track: $e");
      rethrow;
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

  // Use MediaItem duration as source of truth to avoid just_audio's
  // incorrect bitrate estimation for YouTube streams.
  Stream<Duration?> get durationStream =>
      mediaItem.map((item) => item?.duration);
}
