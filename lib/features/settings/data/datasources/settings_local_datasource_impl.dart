import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/error/exceptions.dart';
import '../models/settings_model.dart';
import '../models/user_model.dart';
import 'settings_local_datasource.dart';

class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  final SharedPreferences sharedPreferences;

  static const String _userKey = 'current_user';
  static const String _settingsKey = 'app_settings';
  static const String _audioQualityKey = 'audio_quality';
  static const String _downloadOverCellularKey = 'download_over_cellular';
  static const String _pushNotificationsKey = 'push_notifications';

  SettingsLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<UserModel> getCurrentUser() async {
    final jsonString = sharedPreferences.getString(_userKey);
    if (jsonString != null) {
      return UserModel.fromJson(json.decode(jsonString));
    }
    // Return mock user for demo
    return const UserModel(
      id: '1',
      name: 'Alex Rivera',
      email: 'alex.rivera@modern-rhythm.io',
      avatarUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuCIT6hbv4-EID8wL8_EszMQOsesWAS-KGBMsTqqMV8X9OQItULU-Rgzmb6VKahaFO9zq1jK8No2aREE8Mpwuanc9xmOOHkW8baCR1KYTOp-CgbHIjT5HxnYJuAu2fXpRwRd1Gf0vNe6w05VAkFdcyXWYhF5WL0Pt9K1Cc32g2bNTUefHo_R0LZ2-6yg3lS-t0SkH6IEKv0ZaB0FqroUU2E12AM51SpeQa0xIx7zI6Sh8wQJpArxynk8Sr-4Qxo06FIZWy6M39jsEo0',
    );
  }

  @override
  Future<SettingsModel> getSettings() async {
    final jsonString = sharedPreferences.getString(_settingsKey);
    if (jsonString != null) {
      return SettingsModel.fromJson(json.decode(jsonString));
    }
    return const SettingsModel();
  }

  @override
  Future<SettingsModel> saveAudioQuality(String quality) async {
    try {
      await sharedPreferences.setString(_audioQualityKey, quality);
      return await getSettings();
    } catch (e) {
      throw CacheException('Failed to save audio quality: $e');
    }
  }

  @override
  Future<SettingsModel> saveDownloadOverCellular(bool value) async {
    try {
      await sharedPreferences.setBool(_downloadOverCellularKey, value);
      return await getSettings();
    } catch (e) {
      throw CacheException('Failed to save download setting: $e');
    }
  }

  @override
  Future<SettingsModel> savePushNotifications(bool value) async {
    try {
      await sharedPreferences.setBool(_pushNotificationsKey, value);
      return await getSettings();
    } catch (e) {
      throw CacheException('Failed to save notification setting: $e');
    }
  }

  @override
  Future<void> logout() async {
    try {
      await sharedPreferences.remove(_userKey);
      await sharedPreferences.remove(_settingsKey);
    } catch (e) {
      throw CacheException('Failed to logout: $e');
    }
  }

  @override
  Future<void> scanLocalFolders() async {
    // TODO: Implement actual local folder scanning
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Future<void> cloudImport() async {
    // TODO: Implement actual cloud import
    await Future.delayed(const Duration(seconds: 1));
  }
}
