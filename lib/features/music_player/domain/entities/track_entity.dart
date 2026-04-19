import 'package:equatable/equatable.dart';

class TrackEntity extends Equatable {
  final String id;
  final String title;
  final String artist;
  final String albumArtUrl;
  final String audioUrl;
  final Duration duration;
  final Duration currentPosition;
  final bool isPlaying;
  final bool isFavorite;
  final String? localPath;
  final String? syncedLyrics;
  final String? plainLyrics;

  const TrackEntity({
    required this.id,
    required this.title,
    required this.artist,
    required this.albumArtUrl,
    required this.audioUrl,
    required this.duration,
    this.currentPosition = Duration.zero,
    this.isPlaying = false,
    this.isFavorite = false,
    this.localPath,
    this.syncedLyrics,
    this.plainLyrics,
  });

  TrackEntity copyWith({
    String? id,
    String? title,
    String? artist,
    String? albumArtUrl,
    String? audioUrl,
    Duration? duration,
    Duration? currentPosition,
    bool? isPlaying,
    bool? isFavorite,
    String? localPath,
    String? syncedLyrics,
    String? plainLyrics,
  }) {
    return TrackEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      albumArtUrl: albumArtUrl ?? this.albumArtUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      duration: duration ?? this.duration,
      currentPosition: currentPosition ?? this.currentPosition,
      isPlaying: isPlaying ?? this.isPlaying,
      isFavorite: isFavorite ?? this.isFavorite,
      localPath: localPath ?? this.localPath,
      syncedLyrics: syncedLyrics ?? this.syncedLyrics,
      plainLyrics: plainLyrics ?? this.plainLyrics,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    artist,
    albumArtUrl,
    duration,
    currentPosition,
    isPlaying,
    isFavorite,
    localPath,
    syncedLyrics,
    plainLyrics,
  ];
}
