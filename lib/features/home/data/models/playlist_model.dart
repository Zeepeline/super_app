import 'package:hive/hive.dart';
import '../../domain/entities/playlist_entity.dart';
import '../../../../core/utils/hive_box_constants.dart';

part 'playlist_model.g.dart';

@HiveType(typeId: HiveBoxConstants.playlistTypeId)
class PlaylistModel extends PlaylistEntity {
  @HiveField(0)
  final String idField;
  @HiveField(1)
  final String titleField;
  @HiveField(2)
  final String descriptionField;
  @HiveField(3)
  final String imageUrlField;

  const PlaylistModel({
    required this.idField,
    required this.titleField,
    required this.descriptionField,
    required this.imageUrlField,
  }) : super(
         id: idField,
         title: titleField,
         description: descriptionField,
         imageUrl: imageUrlField,
       );

  factory PlaylistModel.fromJson(Map<String, dynamic> json) {
    return PlaylistModel(
      idField: json['id'],
      titleField: json['title'],
      descriptionField: json['description'],
      imageUrlField: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': idField,
      'title': titleField,
      'description': descriptionField,
      'imageUrl': imageUrlField,
    };
  }
}
