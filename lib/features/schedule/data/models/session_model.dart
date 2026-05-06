import 'package:super_app/features/schedule/domain/entities/session_entity.dart';

class SessionModel extends SessionEntity {
  const SessionModel({
    required super.id,
    required super.time,
    required super.title,
    required super.description,
    required super.tag,
    super.participants,
    super.isLive,
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    return SessionModel(
      id: json['id'],
      time: json['time'],
      title: json['title'],
      description: json['description'],
      tag: json['tag'],
      participants: List<String>.from(json['participants'] ?? []),
      isLive: json['isLive'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'time': time,
      'title': title,
      'description': description,
      'tag': tag,
      'participants': participants,
      'isLive': isLive,
    };
  }
}
