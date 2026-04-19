import 'package:equatable/equatable.dart';

class TrackEntity extends Equatable {
  final String id;
  final String title;
  final String artist;
  final String albumArtUrl;
  final String duration;
  final String audioUrl;
  final bool isFavorite;
  final String? localPath;
  final String? syncedLyrics;
  final String? plainLyrics;

  const TrackEntity({
    required this.id,
    required this.title,
    required this.artist,
    required this.albumArtUrl,
    required this.duration,
    required this.audioUrl,
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
    String? duration,
    String? audioUrl,
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
      duration: duration ?? this.duration,
      audioUrl: audioUrl ?? this.audioUrl,
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
    audioUrl,
    isFavorite,
    localPath,
    syncedLyrics,
    plainLyrics,
  ];
}
