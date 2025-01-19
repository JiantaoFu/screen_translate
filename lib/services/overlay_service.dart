import 'package:flutter/services.dart';

class OverlayService {
  static const MethodChannel _channel =
      MethodChannel('com.example.screen_translate/overlay');

  // Check if we have overlay permission
  Future<bool> checkOverlayPermission() async {
    try {
      final bool hasPermission = await _channel.invokeMethod('checkOverlayPermission');
      return hasPermission;
    } on PlatformException catch (e) {
      print('Error checking overlay permission: ${e.message}');
      return false;
    }
  }

  // Request overlay permission
  Future<bool> requestOverlayPermission() async {
    try {
      final bool granted = await _channel.invokeMethod('requestOverlayPermission');
      return granted;
    } on PlatformException catch (e) {
      print('Error requesting overlay permission: ${e.message}');
      return false;
    }
  }

  // Show overlay with translated text
  Future<bool> showTranslationOverlay(String text, int id, {double? x, double? y}) async {
    try {
      final bool shown = await _channel.invokeMethod('showTranslationOverlay', {
        'text': text,
        'id': id,
        'x': x,
        'y': y,
      });
      return shown;
    } on PlatformException catch (e) {
      print('Error showing translation overlay: ${e.message}');
      return false;
    }
  }

  // Hide all overlays
  Future<bool> hideTranslationOverlay() async {
    try {
      final bool hidden = await _channel.invokeMethod('hideTranslationOverlay');
      return hidden;
    } on PlatformException catch (e) {
      print('Error hiding translation overlay: ${e.message}');
      return false;
    }
  }
}
