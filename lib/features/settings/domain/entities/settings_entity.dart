import 'package:equatable/equatable.dart';

enum AudioQuality { standard, high, lossless }

class SettingsEntity extends Equatable {
  final AudioQuality audioQuality;
  final bool downloadOverCellular;
  final bool pushNotifications;
  final String? currentUserId;

  const SettingsEntity({
    this.audioQuality = AudioQuality.high,
    this.downloadOverCellular = false,
    this.pushNotifications = true,
    this.currentUserId,
  });

  SettingsEntity copyWith({
    AudioQuality? audioQuality,
    bool? downloadOverCellular,
    bool? pushNotifications,
    String? currentUserId,
  }) {
    return SettingsEntity(
      audioQuality: audioQuality ?? this.audioQuality,
      downloadOverCellular: downloadOverCellular ?? this.downloadOverCellular,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      currentUserId: currentUserId ?? this.currentUserId,
    );
  }

  @override
  List<Object?> get props => [
    audioQuality,
    downloadOverCellular,
    pushNotifications,
    currentUserId,
  ];
}
