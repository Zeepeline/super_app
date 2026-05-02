import 'package:dartz/dartz.dart';
import 'package:super_app/core/services/youtube_download_service.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/services/audio_handler.dart';
import '../../../home/data/datasources/home_local_data_source.dart';
import '../../domain/entities/playlist_entity.dart';
import '../../domain/entities/track_entity.dart';
import '../../domain/repositories/music_repository.dart';
import '../datasources/music_local_datasource.dart';
import '../models/track_model.dart';

class MusicRepositoryImpl implements MusicRepository {
  final MusicLocalDataSource localDataSource;
  final HomeLocalDataSource homeLocalDataSource;
  final AudioHandler audioHandler;
  final YoutubeDownloadService youtubeDownloadService;

  MusicRepositoryImpl({
    required this.localDataSource,
    required this.homeLocalDataSource,
    required this.audioHandler,
    required this.youtubeDownloadService,
  }) {
    audioHandler.onSkipNextCallback = () => skipToNext();
    audioHandler.onSkipPreviousCallback = () => skipToPrevious();

    // Sync real-time playback status to local data source
    audioHandler.playbackState.listen((state) {
      localDataSource.updateTrackState(isPlaying: state.playing);
    });

    // Sync media item changes to local data source current track
    // (This handles external changes from iOS/Android system controls)
    audioHandler.mediaItem.listen((item) {
      if (item != null) {
        final current = localDataSource.getCurrentTrack();
        if (current.id != item.id) {
          localDataSource.setCurrentTrack(
            TrackModel(
              id: item.id,
              title: item.title,
              artist: item.artist ?? 'Unknown',
              albumArtUrl: item.artUri?.toString() ?? '',
              duration: item.duration ?? Duration.zero,
              audioUrl: '',
              isFavorite: current.isFavorite,
            ),
          );
        }
      }
    });
  }

  /// Ensures a track has a valid (non-expired) URL if it's a streaming track
  Future<TrackEntity> _ensureValidAudioUrl(TrackEntity track) async {
    // If it's a local file, no need to refresh URL
    if (track.localPath != null && track.localPath!.isNotEmpty) {
      return track;
    }

    // If it looks like a YouTube ID (11 chars) and has no local path, refresh it
    if (track.id.length == 11) {
      try {
        print("MusicRepository: Refreshing stream URL for ${track.id}...");
        final newUrl = await youtubeDownloadService.getStreamUrl(track.id);
        if (newUrl != null && newUrl.isNotEmpty) {
          return track.copyWith(audioUrl: newUrl);
        }
      } catch (e) {
        print("MusicRepository: Failed to refresh URL: $e");
      }
    }
    return track;
  }

  @override
  Future<void> initializePlayer() async {
    try {
      final tracks = await homeLocalDataSource.getPopularTracks();
      if (tracks.isNotEmpty) {
        // Convert home TrackModels to music_player TrackModels
        final playerTracks = tracks.map((t) {
          // Parse duration string "m:ss" to Duration
          final parts = t.duration.split(':');
          int minutes = 0;
          int seconds = 0;
          if (parts.length > 1) {
            minutes = int.tryParse(parts[0]) ?? 0;
            seconds = int.tryParse(parts[1]) ?? 0;
          } else {
            seconds = int.tryParse(parts[0]) ?? 0;
          }

          return TrackModel(
            id: t.id,
            title: t.title,
            artist: t.artist,
            albumArtUrl: t.albumArtUrl,
            duration: Duration(minutes: minutes, seconds: seconds),
            audioUrl: t.audioUrl,
            localPath: t.localPath,
            syncedLyrics: t.syncedLyrics,
            plainLyrics: t.plainLyrics,
          );
        }).toList();

        localDataSource.setCurrentTrack(
          playerTracks.first,
          queue: playerTracks,
        );
      }
    } catch (e) {
      print("MusicRepositoryImpl: Error initializing player from library: $e");
    }
  }

  @override
  Future<Either<Failure, TrackEntity>> getCurrentTrack() async {
    try {
      final track = localDataSource.getCurrentTrack();
      return Right(track);
    } catch (e) {
      return const Left(CacheFailure('Failed to get current track'));
    }
  }

  @override
  Future<Either<Failure, PlaylistEntity>> getCurrentPlaylist() async {
    try {
      final playlist = localDataSource.getCurrentPlaylist();
      return Right(playlist);
    } catch (e) {
      return const Left(CacheFailure('Failed to get current playlist'));
    }
  }

  @override
  Future<Either<Failure, TrackEntity>> playTrack(
    String trackId, {
    TrackEntity? track,
  }) async {
    try {
      // If a full track is provided, set it as current first
      if (track != null) {
        localDataSource.setCurrentTrack(TrackModel.fromEntity(track));
      }
      
      var trackToPlay = localDataSource.getCurrentTrack();
      
      // Refresh URL if needed before sending to handler
      final refreshedTrack = await _ensureValidAudioUrl(trackToPlay);
      
      await audioHandler.playTrack(refreshedTrack);
      final updatedTrack = localDataSource.updateTrackState(
        isPlaying: true,
        currentPosition: Duration.zero,
      );
      return Right(updatedTrack);
    } catch (e) {
      return const Left(CacheFailure('Failed to play track'));
    }
  }

  @override
  Future<Either<Failure, TrackEntity>> pauseTrack() async {
    try {
      await audioHandler.pause();
      final track = localDataSource.updateTrackState(isPlaying: false);
      return Right(track);
    } catch (e) {
      return const Left(CacheFailure('Failed to pause track'));
    }
  }

  @override
  Future<Either<Failure, TrackEntity>> seekTo(Duration position) async {
    try {
      await audioHandler.seek(position);
      final track = localDataSource.updateTrackState(currentPosition: position);
      return Right(track);
    } catch (e) {
      return const Left(CacheFailure('Failed to seek to position'));
    }
  }

  @override
  Future<Either<Failure, TrackEntity>> toggleFavorite(String trackId) async {
    try {
      final currentTrack = localDataSource.getCurrentTrack();
      final newFavoriteState = !currentTrack.isFavorite;
      final track = localDataSource.updateFavoriteState(
        trackId: trackId,
        isFavorite: newFavoriteState,
      );

      // Persist to HomeLocalDataSource (Hive)
      await homeLocalDataSource.updateTrackFavoriteStatus(
        trackId,
        newFavoriteState,
      );

      return Right(track);
    } catch (e) {
      return const Left(CacheFailure('Failed to toggle favorite'));
    }
  }

  @override
  Future<Either<Failure, TrackEntity>> skipToNext() async {
    try {
      final nextTrack = localDataSource.getNextTrack();
      
      // Refresh URL if needed
      final refreshedTrack = await _ensureValidAudioUrl(nextTrack);
      
      // Ensure we set it as playing in our local state
      final updatedTrack = localDataSource.updateTrackState(
        isPlaying: true,
        currentPosition: Duration.zero,
      );
      
      // Use the refreshed track for playback
      await audioHandler.playTrack(refreshedTrack);
      
      return Right(updatedTrack);
    } catch (e) {
      return const Left(CacheFailure('Failed to skip to next track'));
    }
  }

  @override
  Future<Either<Failure, TrackEntity>> skipToPrevious() async {
    try {
      final prevTrack = localDataSource.getPreviousTrack();
      
      // Refresh URL if needed
      final refreshedTrack = await _ensureValidAudioUrl(prevTrack);
      
      // Ensure we set it as playing in our local state
      final updatedTrack = localDataSource.updateTrackState(
        isPlaying: true,
        currentPosition: Duration.zero,
      );
      
      // Use the refreshed track for playback
      await audioHandler.playTrack(refreshedTrack);
      
      return Right(updatedTrack);
    } catch (e) {
      return const Left(CacheFailure('Failed to skip to previous track'));
    }
  }

  @override
  Future<Either<Failure, TrackEntity>> toggleShuffle() async {
    try {
      localDataSource.toggleShuffle();
      return getCurrentTrack();
    } catch (e) {
      return const Left(CacheFailure('Failed to toggle shuffle'));
    }
  }

  @override
  Future<Either<Failure, TrackEntity>> toggleRepeat() async {
    try {
      final isRepeat = localDataSource.toggleRepeat();
      await audioHandler.setLoopMode(isRepeat);
      return getCurrentTrack();
    } catch (e) {
      return const Left(CacheFailure('Failed to toggle repeat'));
    }
  }

  @override
  bool getShuffleState() => localDataSource.isShuffleEnabled();

  @override
  bool getRepeatState() => localDataSource.isRepeatEnabled();

  @override
  Stream<bool> get isPlayingStream =>
      audioHandler.playerStateStream.map((state) => state.playing);

  @override
  Stream<Duration> get positionStream => audioHandler.positionStream;

  @override
  Stream<Duration?> get durationStream => audioHandler.durationStream;

  @override
  Stream<TrackEntity?> get currentTrackStream => audioHandler.mediaItem.map((
    item,
  ) {
    if (item == null) return null;
    // Sync the ID back to local data source current track if they differ
    final currentTrack = localDataSource.getCurrentTrack();
    if (currentTrack.id != item.id) {
      // This allows navigation from system controls to update our local state
      final newTrack = TrackModel(
        id: item.id,
        title: item.title,
        artist: item.artist ?? 'Unknown',
        albumArtUrl: item.artUri?.toString() ?? '',
        duration: item.duration ?? Duration.zero,
        audioUrl: '', // URL is not always known from MediaItem
      );
      localDataSource.setCurrentTrack(newTrack);
    }
    return localDataSource.getCurrentTrack();
  });

  @override
  Future<void> saveLyrics(String path, String? synced, String? plain) async {
    await homeLocalDataSource.updateTrackLyrics(path, synced, plain);
  }
}
