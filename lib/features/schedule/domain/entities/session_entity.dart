import 'package:equatable/equatable.dart';

class SessionEntity extends Equatable {
  final String id;
  final String time;
  final String title;
  final String description;
  final String tag;
  final List<String> participants;
  final bool isLive;

  const SessionEntity({
    required this.id,
    required this.time,
    required this.title,
    required this.description,
    required this.tag,
    this.participants = const [],
    this.isLive = false,
  });

  @override
  List<Object?> get props => [
    id,
    time,
    title,
    description,
    tag,
    participants,
    isLive,
  ];
}
