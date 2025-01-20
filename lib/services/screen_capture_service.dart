import 'dart:async';
import 'package:flutter/services.dart';

class ScreenCaptureService {
  static const platform = MethodChannel('com.example.screen_translate/screen_capture');
  bool _isCapturing = false;
  Timer? _debounceTimer;
  static const _debounceTime = Duration(milliseconds: 500);

  Future<bool> requestScreenCapture() async {
    try {
      final Map<String, dynamic> result = await platform.invokeMethod('requestScreenCapture');
      return result != null;
    } on PlatformException catch (e) {
      print('Error requesting screen capture: ${e.message}');
      return false;
    }
  }

  Future<bool> startScreenCapture(Map<String, dynamic> data) async {
    if (_isCapturing) return true;
    
    try {
      await platform.invokeMethod('startScreenCapture', {
        'resultCode': data['resultCode'],
        'data': data,
      });
      _isCapturing = true;
      return true;
    } on PlatformException catch (e) {
      print('Error starting screen capture: ${e.message}');
      return false;
    }
  }

  Future<void> stopScreenCapture() async {
    if (!_isCapturing) return;
    
    try {
      _debounceTimer?.cancel();
      await platform.invokeMethod('stopScreenCapture');
      _isCapturing = false;
    } on PlatformException catch (e) {
      print('Error stopping screen capture: ${e.message}');
    }
  }

  // This method returns a debounced stream of screen captures
  Stream<Uint8List> watchScreen() async* {
    if (!_isCapturing) return;

    StreamController<Uint8List>? controller;
    Timer? debounceTimer;
    bool isProcessing = false;

    void cleanup() {
      debounceTimer?.cancel();
      controller?.close();
    }

    try {
      controller = StreamController<Uint8List>(
        onCancel: cleanup,
      );

      while (_isCapturing) {
        if (!isProcessing) {
          isProcessing = true;
          
          // Cancel previous timer
          debounceTimer?.cancel();
          
          // Start new timer
          debounceTimer = Timer(_debounceTime, () async {
            try {
              final result = await platform.invokeMethod('captureScreen');
              if (result != null && controller?.isClosed == false) {
                controller?.add(result as Uint8List);
              }
            } catch (e) {
              print('Error in capture: $e');
            } finally {
              isProcessing = false;
            }
          });
        }
        
        // Small delay to prevent tight loop
        await Future.delayed(const Duration(milliseconds: 100));
      }
    } finally {
      cleanup();
    }
  }

  // For single captures (if needed)
  Future<Uint8List?> captureScreen() async {
    if (!_isCapturing) return null;
    
    try {
      final result = await platform.invokeMethod('captureScreen');
      return result as Uint8List?;
    } on PlatformException catch (e) {
      print('Error capturing screen: ${e.message}');
      return null;
    }
  }

  bool get isCapturing => _isCapturing;
}
