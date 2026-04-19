import '../../domain/entities/settings_entity.dart';

class SettingsModel extends SettingsEntity {
  const SettingsModel({
    super.audioQuality = AudioQuality.high,
    super.downloadOverCellular = false,
    super.pushNotifications = true,
    super.currentUserId,
  });

  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      audioQuality: AudioQuality.values.firstWhere(
        (e) => e.name == json['audio_quality'],
        orElse: () => AudioQuality.high,
      ),
      downloadOverCellular: json['download_over_cellular'] as bool? ?? false,
      pushNotifications: json['push_notifications'] as bool? ?? true,
      currentUserId: json['current_user_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'audio_quality': audioQuality.name,
      'download_over_cellular': downloadOverCellular,
      'push_notifications': pushNotifications,
      'current_user_id': currentUserId,
    };
  }

  @override
  SettingsModel copyWith({
    AudioQuality? audioQuality,
    bool? downloadOverCellular,
    bool? pushNotifications,
    String? currentUserId,
  }) {
    return SettingsModel(
      audioQuality: audioQuality ?? this.audioQuality,
      downloadOverCellular: downloadOverCellular ?? this.downloadOverCellular,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      currentUserId: currentUserId ?? this.currentUserId,
    );
  }
}
