import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class OverlayService {
  static const MethodChannel _channel =
      MethodChannel('com.lomoware.screen_translate/overlay');

  // Static method to show overlay permission dialog
  static Future<bool> showOverlayPermissionDialog(BuildContext context) async {
    bool? result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.overlay_permission_required),
        content: Text(AppLocalizations.of(context)!.overlay_permission_required_content),
        actions: [
          TextButton(
            child: Text(AppLocalizations.of(context)!.cancel),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: Text(AppLocalizations.of(context)!.grant_permission),
            onPressed: () {
              _channel.invokeMethod('requestOverlayPermission');
              Navigator.of(context).pop(true);
            },
          ),
        ],
      ),
    );
    
    return result ?? false;
  }

  // Ensure overlay permission
  Future<bool> ensureOverlayPermission(BuildContext context) async {
    bool hasPermission = await checkOverlayPermission();
    if (!hasPermission) {
      hasPermission = await showOverlayPermissionDialog(context);
      
      // Recheck permission after request
      return await checkOverlayPermission();
    }
    return hasPermission;
  }

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
  Future<bool> showTranslationOverlay(String text, int id, {double? x, double? y, double? width, double? height, Color? overlayColor, Color? backgroundColor, bool? isLight, double? imgWidth, double? imgHeight}) async {
    try {
      final bool shown = await _channel.invokeMethod('showTranslationOverlay', {
        'text': text,
        'id': id,
        'x': x,
        'y': y,
        'width': width,
        'height': height,
        'overlayColor': overlayColor?.value,
        'backgroundColor': backgroundColor?.value,
        'isLight': isLight,
        'imgWidth': imgWidth,
        'imgHeight': imgHeight,
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

  Future<bool> start() async {
    try {
      final bool succ = await _channel.invokeMethod('startTranslationOverlay');
      return succ;
    } on PlatformException catch (e) {
      print('Error starting translation overlay: ${e.message}');
      return false;
    }
  }

  Future<bool> stop() async {
    try {
      final bool succ = await _channel.invokeMethod('stopTranslationOverlay');
      return succ;
    } on PlatformException catch (e) {
      print('Error stopping translation overlay: ${e.message}');
      return false;
    }
  }
}
