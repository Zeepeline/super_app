import 'package:super_app/features/music_player/domain/entities/track_entity.dart';

class TrackModel extends TrackEntity {
  const TrackModel({
    required String id,
    required String title,
    required String artist,
    required String albumArtUrl,
    required Duration duration,
    required String audioUrl,
    Duration currentPosition = Duration.zero,
    bool isPlaying = false,
    bool isFavorite = false,
    String? localPath,
    String? syncedLyrics,
    String? plainLyrics,
  }) : super(
         id: id,
         title: title,
         artist: artist,
         albumArtUrl: albumArtUrl,
         duration: duration,
         currentPosition: currentPosition,
         isPlaying: isPlaying,
         isFavorite: isFavorite,
         localPath: localPath,
         audioUrl: audioUrl,
         syncedLyrics: syncedLyrics,
         plainLyrics: plainLyrics,
       );

  factory TrackModel.fromJson(Map<String, dynamic> json) {
    return TrackModel(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      albumArtUrl: json['album_art_url'] as String,
      duration: Duration(milliseconds: json['duration_ms'] as int),
      currentPosition: Duration(
        milliseconds: json['current_position_ms'] as int? ?? 0,
      ),
      isPlaying: json['is_playing'] as bool? ?? false,
      isFavorite: json['is_favorite'] as bool? ?? false,
      localPath: json['local_path'] as String?,
      audioUrl: json['audio_url'] as String,
      syncedLyrics: json['synced_lyrics'] as String?,
      plainLyrics: json['plain_lyrics'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album_art_url': albumArtUrl,
      'duration_ms': duration.inMilliseconds,
      'current_position_ms': currentPosition.inMilliseconds,
      'is_playing': isPlaying,
      'is_favorite': isFavorite,
      'local_path': localPath,
      'synced_lyrics': syncedLyrics,
      'plain_lyrics': plainLyrics,
    };
  }

  factory TrackModel.fromEntity(TrackEntity entity) {
    return TrackModel(
      id: entity.id,
      title: entity.title,
      artist: entity.artist,
      albumArtUrl: entity.albumArtUrl,
      duration: entity.duration,
      currentPosition: entity.currentPosition,
      isPlaying: entity.isPlaying,
      isFavorite: entity.isFavorite,
      localPath: entity.localPath,
      audioUrl: entity.audioUrl,
      syncedLyrics: entity.syncedLyrics,
      plainLyrics: entity.plainLyrics,
    );
  }

  @override
  TrackModel copyWith({
    String? id,
    String? title,
    String? artist,
    String? albumArtUrl,
    Duration? duration,
    Duration? currentPosition,
    bool? isPlaying,
    bool? isFavorite,
    String? localPath,
    String? audioUrl,
    String? syncedLyrics,
    String? plainLyrics,
  }) {
    return TrackModel(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      albumArtUrl: albumArtUrl ?? this.albumArtUrl,
      duration: duration ?? this.duration,
      currentPosition: currentPosition ?? this.currentPosition,
      isPlaying: isPlaying ?? this.isPlaying,
      isFavorite: isFavorite ?? this.isFavorite,
      localPath: localPath ?? this.localPath,
      audioUrl: audioUrl ?? this.audioUrl,
      syncedLyrics: syncedLyrics ?? this.syncedLyrics,
      plainLyrics: plainLyrics ?? this.plainLyrics,
    );
  }
}
