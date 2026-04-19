import 'package:equatable/equatable.dart';

import '../../domain/entities/settings_entity.dart';
import '../../domain/entities/user_entity.dart';

abstract class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object?> get props => [];
}

class SettingsInitial extends SettingsState {
  const SettingsInitial();
}

class SettingsLoading extends SettingsState {
  const SettingsLoading();
}

class SettingsLoaded extends SettingsState {
  final SettingsEntity settings;
  final UserEntity? user;

  const SettingsLoaded({required this.settings, this.user});

  @override
  List<Object?> get props => [settings, user];

  SettingsLoaded copyWith({SettingsEntity? settings, UserEntity? user}) {
    return SettingsLoaded(
      settings: settings ?? this.settings,
      user: user ?? this.user,
    );
  }
}

class SettingsError extends SettingsState {
  final String message;

  const SettingsError(this.message);

  @override
  List<Object?> get props => [message];
}

class LogoutSuccess extends SettingsState {
  const LogoutSuccess();
}

class SettingsImporting extends SettingsLoaded {
  const SettingsImporting({required super.settings, super.user});
}

class SettingsImportSuccess extends SettingsLoaded {
  final int count;
  const SettingsImportSuccess({
    required super.settings,
    super.user,
    required this.count,
  });

  @override
  List<Object?> get props => [...super.props, count];
}

class SettingsDownloadingYoutube extends SettingsLoaded {
  final String stage;
  final double progress;
  const SettingsDownloadingYoutube({
    required super.settings,
    super.user,
    required this.stage,
    required this.progress,
  });

  @override
  List<Object?> get props => [...super.props, stage, progress];
}

class SettingsDownloadSuccess extends SettingsLoaded {
  final String title;
  const SettingsDownloadSuccess({
    required super.settings,
    super.user,
    required this.title,
  });

  @override
  List<Object?> get props => [...super.props, title];
}
