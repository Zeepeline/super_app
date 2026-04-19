import 'package:hive/hive.dart';
import '../../domain/entities/track_entity.dart';
import '../../../../core/utils/hive_box_constants.dart';

part 'track_model.g.dart';

@HiveType(typeId: HiveBoxConstants.trackTypeId)
class TrackModel extends TrackEntity {
  @HiveField(0)
  final String idField;
  @HiveField(1)
  final String titleField;
  @HiveField(2)
  final String artistField;
  @HiveField(3)
  final String albumArtUrlField;
  @HiveField(4)
  final String durationField;
  @HiveField(5)
  final String audioUrlField;
  @HiveField(6)
  final String? localPathField;
  @HiveField(7)
  final bool isFavoriteField;
  @HiveField(8)
  final String? syncedLyricsField;
  @HiveField(9)
  final String? plainLyricsField;

  const TrackModel({
    required this.idField,
    required this.titleField,
    required this.artistField,
    required this.albumArtUrlField,
    required this.durationField,
    required this.audioUrlField,
    this.localPathField,
    this.isFavoriteField = false,
    this.syncedLyricsField,
    this.plainLyricsField,
  }) : super(
          id: idField,
          title: titleField,
          artist: artistField,
          albumArtUrl: albumArtUrlField,
          duration: durationField,
          audioUrl: audioUrlField,
          isFavorite: isFavoriteField,
          localPath: localPathField,
          syncedLyrics: syncedLyricsField,
          plainLyrics: plainLyricsField,
        );

  @override
  TrackModel copyWith({
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
    return TrackModel(
      idField: id ?? idField,
      titleField: title ?? titleField,
      artistField: artist ?? artistField,
      albumArtUrlField: albumArtUrl ?? albumArtUrlField,
      durationField: duration ?? durationField,
      audioUrlField: audioUrl ?? audioUrlField,
      isFavoriteField: isFavorite ?? isFavoriteField,
      localPathField: localPath ?? localPathField,
      syncedLyricsField: syncedLyrics ?? syncedLyricsField,
      plainLyricsField: plainLyrics ?? plainLyricsField,
    );
  }

  factory TrackModel.fromJson(Map<String, dynamic> json) {
    return TrackModel(
      idField: json['id'] ?? '',
      titleField: json['title'] ?? '',
      artistField: json['artist'] ?? '',
      albumArtUrlField: json['albumArtUrl'] ?? '',
      durationField: json['duration'] ?? '',
      audioUrlField: json['audioUrl'] ?? '',
      isFavoriteField: json['isFavorite'] ?? false,
      localPathField: json['localPath'],
      syncedLyricsField: json['syncedLyrics'],
      plainLyricsField: json['plainLyrics'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': idField,
      'title': titleField,
      'artist': artistField,
      'albumArtUrl': albumArtUrlField,
      'duration': durationField,
      'audioUrl': audioUrlField,
      'isFavorite': isFavoriteField,
      'localPath': localPathField,
      'syncedLyrics': syncedLyricsField,
      'plainLyrics': plainLyricsField,
    };
  }
}
