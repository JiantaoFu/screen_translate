import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

class DeviceInfoService {
  static final DeviceInfoService _instance = DeviceInfoService._internal();
  final Logger _logger = Logger('DeviceInfoService');
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  String? _deviceId;

  factory DeviceInfoService() {
    return _instance;
  }

  DeviceInfoService._internal();

  Future<String?> getDeviceId() async {
    if (_deviceId != null) {
      return _deviceId;
    }

    try {
      if (kIsWeb) {
        // Web does not have a stable device ID, you might need a different strategy
        _logger.warning('Device ID is not available on web.');
        return null;
      } else {
        if (Platform.isAndroid) {
          final androidInfo = await _deviceInfo.androidInfo;
          _deviceId = androidInfo.id; // Consistent after factory reset
        } else if (Platform.isIOS) {
          final iosInfo = await _deviceInfo.iosInfo;
          _deviceId = iosInfo.identifierForVendor; // Unique per vendor
        } else {
          _logger.warning('Unsupported platform for device ID.');
          return null;
        }
      }
    } catch (e, stackTrace) {
      _logger.severe('Failed to get device ID', e, stackTrace);
      return null;
    }
    
    _logger.info('Device ID: $_deviceId');
    return _deviceId;
  }
}
