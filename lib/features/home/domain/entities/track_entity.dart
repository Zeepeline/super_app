import 'package:equatable/equatable.dart';

class TrackEntity extends Equatable {
  final String id;
  final String title;
  final String artist;
  final String album;
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
    required this.album,
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
    String? album,
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
      album: album ?? this.album,
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
    album,
    albumArtUrl,
    duration,
    audioUrl,
    isFavorite,
    localPath,
    syncedLyrics,
    plainLyrics,
  ];
}

extension TrackEntityX on TrackEntity {
  /// Converts the duration string (e.g. "03:45") to a [Duration] object.
  Duration get durationObject {
    if (duration.isEmpty) return Duration.zero;
    final parts = duration.split(':');
    if (parts.length == 2) {
      return Duration(
        minutes: int.tryParse(parts[0]) ?? 0,
        seconds: int.tryParse(parts[1]) ?? 0,
      );
    } else if (parts.length == 3) {
      return Duration(
        hours: int.tryParse(parts[0]) ?? 0,
        minutes: int.tryParse(parts[1]) ?? 0,
        seconds: int.tryParse(parts[2]) ?? 0,
      );
    }
    return Duration.zero;
  }
}
