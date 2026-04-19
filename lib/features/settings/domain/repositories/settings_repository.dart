import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/settings_entity.dart';
import '../entities/user_entity.dart';

abstract class SettingsRepository {
  Future<Either<Failure, UserEntity>> getCurrentUser();
  Future<Either<Failure, SettingsEntity>> getSettings();
  Future<Either<Failure, SettingsEntity>> updateAudioQuality(
    AudioQuality quality,
  );
  Future<Either<Failure, SettingsEntity>> updateDownloadOverCellular(
    bool value,
  );
  Future<Either<Failure, SettingsEntity>> updatePushNotifications(bool value);
  Future<Either<Failure, void>> logout();
  Future<Either<Failure, void>> scanLocalFolders();
  Future<Either<Failure, void>> cloudImport();
}
