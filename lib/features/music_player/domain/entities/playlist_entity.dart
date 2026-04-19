import 'package:equatable/equatable.dart';

class PlaylistEntity extends Equatable {
  final String id;
  final String name;
  final String? coverImageUrl;
  final int trackCount;

  const PlaylistEntity({
    required this.id,
    required this.name,
    this.coverImageUrl,
    this.trackCount = 0,
  });

  @override
  List<Object?> get props => [id, name, coverImageUrl, trackCount];
}
