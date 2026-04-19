import 'package:equatable/equatable.dart';

class LyricLine extends Equatable {
  final Duration startTime;
  final String text;

  const LyricLine({required this.startTime, required this.text});

  @override
  List<Object?> get props => [startTime, text];
}
