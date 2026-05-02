import 'package:equatable/equatable.dart';

import '../../domain/entities/settings_entity.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

class LoadSettingsEvent extends SettingsEvent {
  const LoadSettingsEvent();
}

class LoadUserEvent extends SettingsEvent {
  const LoadUserEvent();
}

class UpdateAudioQualityEvent extends SettingsEvent {
  final AudioQuality quality;

  const UpdateAudioQualityEvent(this.quality);

  @override
  List<Object?> get props => [quality];
}

class UpdateDownloadOverCellularEvent extends SettingsEvent {
  final bool value;

  const UpdateDownloadOverCellularEvent(this.value);

  @override
  List<Object?> get props => [value];
}

class UpdatePushNotificationsEvent extends SettingsEvent {
  final bool value;

  const UpdatePushNotificationsEvent(this.value);

  @override
  List<Object?> get props => [value];
}

class LogoutEvent extends SettingsEvent {
  const LogoutEvent();
}

class ScanLocalFoldersEvent extends SettingsEvent {
  const ScanLocalFoldersEvent();
}

class CloudImportEvent extends SettingsEvent {
  const CloudImportEvent();
}

class LoadBundledMusicEvent extends SettingsEvent {
  const LoadBundledMusicEvent();
}

class DownloadYoutubeTrackEvent extends SettingsEvent {
  final String url;
  const DownloadYoutubeTrackEvent(this.url);

  @override
  List<Object?> get props => [url];
}

class SyncDownloadedMusicEvent extends SettingsEvent {
  const SyncDownloadedMusicEvent();
}

class UpdateGeminiApiKey extends SettingsEvent {
  final String apiKey;
  const UpdateGeminiApiKey(this.apiKey);

  @override
  List<Object?> get props => [apiKey];
}
