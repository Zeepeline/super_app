import 'package:equatable/equatable.dart';
import 'package:super_app/features/music_player/domain/entities/playlist_entity.dart';
import 'package:super_app/features/music_player/domain/entities/track_entity.dart';

abstract class PlayerState extends Equatable {
  const PlayerState();

  @override
  List<Object?> get props => [];
}

class PlayerInitial extends PlayerState {}

class PlayerLoading extends PlayerState {}

class PlayerLoaded extends PlayerState {
  final TrackEntity track;
  final PlaylistEntity playlist;
  final bool isShuffle;
  final bool isRepeat;
  final bool showLyrics;

  const PlayerLoaded({
    required this.track,
    required this.playlist,
    this.isShuffle = false,
    this.isRepeat = false,
    this.showLyrics = false,
  });

  PlayerLoaded copyWith({
    TrackEntity? track,
    PlaylistEntity? playlist,
    bool? isShuffle,
    bool? isRepeat,
    bool? showLyrics,
  }) {
    return PlayerLoaded(
      track: track ?? this.track,
      playlist: playlist ?? this.playlist,
      isShuffle: isShuffle ?? this.isShuffle,
      isRepeat: isRepeat ?? this.isRepeat,
      showLyrics: showLyrics ?? this.showLyrics,
    );
  }

  @override
  List<Object?> get props => [track, playlist, isShuffle, isRepeat, showLyrics];
}

class PlayerError extends PlayerState {
  final String message;

  const PlayerError(this.message);

  @override
  List<Object?> get props => [message];
}
