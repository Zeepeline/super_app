import 'dart:io';

import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:volume_controller/volume_controller.dart';

class NativeDeviceService {
  final Battery _battery = Battery();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Mendapatkan level baterai saat ini.
  Future<int> getBatteryLevel() async {
    return await _battery.batteryLevel;
  }

  /// Mendapatkan status koneksi internet.
  Future<String> getConnectivityStatus() async {
    final result = await Connectivity().checkConnectivity();
    return result.name;
  }

  /// Mengatur volume sistem (0.0 sampai 1.0).
  Future<void> setVolume(double level) async {
    VolumeController.instance.setVolume(level);
  }

  /// Mendapatkan volume sistem saat ini.
  Future<double> getVolume() async {
    return await VolumeController.instance.getVolume();
  }

  /// Mendapatkan informasi dasar perangkat.
  Future<Map<String, dynamic>> getDeviceInfo() async {
    if (Platform.isAndroid) {
      final info = await _deviceInfo.androidInfo;
      return {
        "model": info.model,
        "brand": info.brand,
        "version": info.version.release,
      };
    } else if (Platform.isIOS) {
      final info = await _deviceInfo.iosInfo;
      return {
        "model": info.utsname.machine,
        "name": info.name,
        "version": info.systemVersion,
      };
    }
    return {"status": "unknown"};
  }

  /// Mendapatkan informasi aplikasi.
  Future<String> getAppInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return "${packageInfo.appName} v${packageInfo.version}";
  }
}
