import 'dart:math';

import 'package:super_app/features/music_player/data/models/track_model.dart';
import 'package:super_app/features/music_player/domain/entities/playlist_entity.dart';

abstract class MusicLocalDataSource {
  /// Get the currently loaded track
  TrackModel getCurrentTrack();

  /// Set the current track to play
  void setCurrentTrack(TrackModel track, {List<TrackModel>? queue});

  /// Get the current playlist
  PlaylistEntity getCurrentPlaylist();

  /// Update track playback state
  TrackModel updateTrackState({bool? isPlaying, Duration? currentPosition});

  /// Update track favorite state
  TrackModel updateFavoriteState({
    required String trackId,
    required bool isFavorite,
  });

  /// Seek to position
  TrackModel seekTo(Duration position);

  /// Get next track in queue
  TrackModel getNextTrack();

  /// Get previous track in queue
  TrackModel getPreviousTrack();

  /// Toggle shuffle mode
  bool toggleShuffle();

  /// Toggle repeat mode
  bool toggleRepeat();

  /// Get current shuffle state
  bool isShuffleEnabled();

  /// Get current repeat state
  bool isRepeatEnabled();
}

class MusicLocalDataSourceImpl implements MusicLocalDataSource {
  TrackModel _currentTrack = const TrackModel(
    id: 'empty',
    title: 'Select a track',
    artist: 'Digital Curator',
    album: 'Unknown Album',
    audioUrl: '',
    albumArtUrl:
        'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?auto=format&fit=crop&q=80&w=300',
    duration: Duration.zero,
    currentPosition: Duration.zero,
    isPlaying: false,
    isFavorite: false,
  );

  final PlaylistEntity _currentPlaylist = const PlaylistEntity(
    id: 'my_library',
    name: 'My Library',
    coverImageUrl:
        'https://images.unsplash.com/photo-1514525253361-bee8ea36b745?auto=format&fit=crop&q=80&w=300',
    trackCount: 0,
  );

  List<TrackModel> _queue = [];
  int _currentIndex = 0;
  bool _isShuffle = false;
  bool _isRepeat = false;

  @override
  TrackModel getCurrentTrack() {
    return _currentTrack;
  }

  @override
  void setCurrentTrack(TrackModel track, {List<TrackModel>? queue}) {
    _currentTrack = track;
    if (queue != null) {
      _queue = queue;
    } else if (_queue.isEmpty) {
      _queue = [track];
    }

    // Always update current index based on the track ID in the queue
    final index = _queue.indexWhere((t) => t.id == track.id);
    if (index != -1) {
      _currentIndex = index;
    } else {
      // If track not in queue, add it and set as current
      _queue.add(track);
      _currentIndex = _queue.length - 1;
    }
  }

  @override
  PlaylistEntity getCurrentPlaylist() {
    return _currentPlaylist;
  }

  @override
  TrackModel updateTrackState({bool? isPlaying, Duration? currentPosition}) {
    _currentTrack = _currentTrack.copyWith(
      isPlaying: isPlaying,
      currentPosition: currentPosition ?? _currentTrack.currentPosition,
    );
    return _currentTrack;
  }

  @override
  TrackModel updateFavoriteState({
    required String trackId,
    required bool isFavorite,
  }) {
    if (_currentTrack.id == trackId) {
      _currentTrack = _currentTrack.copyWith(isFavorite: isFavorite);
    }
    // Also update in queue if exists
    final index = _queue.indexWhere((t) => t.id == trackId);
    if (index != -1) {
      _queue[index] = _queue[index].copyWith(isFavorite: isFavorite);
    }
    return _currentTrack;
  }

  @override
  TrackModel seekTo(Duration position) {
    _currentTrack = _currentTrack.copyWith(currentPosition: position);
    return _currentTrack;
  }

  @override
  TrackModel getNextTrack() {
    if (_queue.isEmpty) return _currentTrack;

    if (_isShuffle) {
      _currentIndex = Random().nextInt(_queue.length);
    } else {
      _currentIndex++;
      if (_currentIndex >= _queue.length) {
        _currentIndex = _isRepeat ? 0 : _queue.length - 1;
      }
    }

    _currentTrack = _queue[_currentIndex];
    return _currentTrack;
  }

  @override
  TrackModel getPreviousTrack() {
    if (_queue.isEmpty) return _currentTrack;

    _currentIndex--;
    if (_currentIndex < 0) {
      _currentIndex = _isRepeat ? _queue.length - 1 : 0;
    }

    _currentTrack = _queue[_currentIndex];
    return _currentTrack;
  }

  @override
  bool toggleShuffle() {
    _isShuffle = !_isShuffle;
    return _isShuffle;
  }

  @override
  bool toggleRepeat() {
    _isRepeat = !_isRepeat;
    return _isRepeat;
  }

  @override
  bool isShuffleEnabled() => _isShuffle;

  @override
  bool isRepeatEnabled() => _isRepeat;
}
