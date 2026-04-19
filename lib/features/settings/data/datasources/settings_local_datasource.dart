import '../models/settings_model.dart';
import '../models/user_model.dart';

abstract class SettingsLocalDataSource {
  Future<UserModel> getCurrentUser();
  Future<SettingsModel> getSettings();
  Future<SettingsModel> saveAudioQuality(String quality);
  Future<SettingsModel> saveDownloadOverCellular(bool value);
  Future<SettingsModel> savePushNotifications(bool value);
  Future<void> logout();
  Future<void> scanLocalFolders();
  Future<void> cloudImport();
}
