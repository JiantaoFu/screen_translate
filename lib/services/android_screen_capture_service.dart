import 'dart:async';
import 'package:flutter/services.dart';

class AndroidScreenCaptureService {
  static const MethodChannel _channel =
      MethodChannel('com.example.screen_translate/screen_capture');

  Future<bool> requestScreenCapture() async {
    try {
      final result = await _channel.invokeMethod('requestScreenCapture');
      if (result is Map) {
        final resultCode = result['resultCode'] as int;
        // Use the serialized intent data
        final intentData = {
          'resultCode': resultCode,
          'intentAction': result['intentAction'],
          'intentFlags': result['intentFlags'],
          'intentDataString': result['intentDataString'],
        };
        
        // Start the screen capture with the permission result
        return await _channel.invokeMethod('startScreenCapture', intentData);
      }
      return false;
    } on PlatformException catch (e) {
      print('Error requesting screen capture: ${e.message}');
      return false;
    }
  }

  Future<void> stopScreenCapture() async {
    try {
      await _channel.invokeMethod('stopScreenCapture');
    } on PlatformException catch (e) {
      print('Error stopping screen capture: ${e.message}');
    }
  }

  Future<Map<String, dynamic>?> captureScreen() async {
    try {
      final result = await _channel.invokeMethod('captureScreen');
      if (result is Map<dynamic, dynamic>) {
        return {
          'bytes': result['bytes'] as Uint8List,
          'width': result['width'] as int,
          'height': result['height'] as int,
        };
      }
      return null;
    } on PlatformException catch (e) {
      print('Error capturing screen: ${e.message}');
      return null;
    }
  }
}
