import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:screen_translate/l10n/app_localizations.dart';

class OverlayService {
  static const MethodChannel _channel =
      MethodChannel('com.lomoware.screen_translate/overlay');

  // Static method to show overlay permission dialog
  static Future<bool> showOverlayPermissionDialog(BuildContext context) async {
    bool? result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.overlay_permission_required),
        content: Text(
            AppLocalizations.of(context)!.overlay_permission_required_content),
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

  // Ensure overlay permission.
  //
  // The system "Display over other apps" page is a separate activity, so the
  // request returns immediately. Previously we re-checked right away (always
  // false on a fresh install) and startTranslation() returned silently: a new
  // buyer granted the permission, came back, and nothing happened. Now we wait
  // until the user is back in the app and then re-check, so the caller can
  // continue straight on to the screen-capture consent.
  Future<bool> ensureOverlayPermission(BuildContext context) async {
    if (await checkOverlayPermission()) return true;
    final openedSettings = await showOverlayPermissionDialog(context);
    if (!openedSettings) return false;
    await waitForAppResume();
    return recheckOverlayPermission(checkOverlayPermission);
  }

  /// Some OEM builds report the overlay grant a moment after we resume, so
  /// poll a few times before giving up.
  @visibleForTesting
  static Future<bool> recheckOverlayPermission(
    Future<bool> Function() check, {
    int attempts = 5,
    Duration interval = const Duration(milliseconds: 300),
  }) async {
    for (var i = 0; i < attempts; i++) {
      if (await check()) return true;
      if (i < attempts - 1) await Future.delayed(interval);
    }
    return false;
  }

  /// Completes once the app has left the foreground (the settings page
  /// opened) and come back to `resumed`, or after [timeout]. A timeout is
  /// not a failure: the caller re-checks the permission either way, so Start
  /// (and `isStarting`) is never held for long.
  static Future<void> waitForAppResume(
      {Duration timeout = const Duration(seconds: 60)}) {
    final observer = ResumeAfterLeavingObserver();
    WidgetsBinding.instance.addObserver(observer);
    return observer.resumed.timeout(timeout, onTimeout: () {}).whenComplete(
          () => WidgetsBinding.instance.removeObserver(observer),
        );
  }

  // Check if we have overlay permission
  Future<bool> checkOverlayPermission() async {
    try {
      final bool hasPermission =
          await _channel.invokeMethod('checkOverlayPermission');
      return hasPermission;
    } on PlatformException catch (e) {
      print('Error checking overlay permission: ${e.message}');
      return false;
    }
  }

  // Request overlay permission
  Future<bool> requestOverlayPermission() async {
    try {
      final bool granted =
          await _channel.invokeMethod('requestOverlayPermission');
      return granted;
    } on PlatformException catch (e) {
      print('Error requesting overlay permission: ${e.message}');
      return false;
    }
  }

  // Show overlay with translated text
  Future<bool> showTranslationOverlay(String text, int id,
      {double? x,
      double? y,
      double? width,
      double? height,
      Color? overlayColor,
      Color? backgroundColor,
      bool? isLight,
      double? imgWidth,
      double? imgHeight}) async {
    try {
      final colorValue = overlayColor?.value;
      final bgColorValue = backgroundColor?.value;
      print(
          'OverlayService.show: id=$id, colorValue=$colorValue (type=${colorValue.runtimeType}), bgColorValue=$bgColorValue (type=${bgColorValue.runtimeType})');

      final args = {
        'text': text,
        'id': id,
        'x': x,
        'y': y,
        'width': width,
        'height': height,
        'overlayColor': colorValue,
        'backgroundColor': bgColorValue,
        'isLight': isLight,
        'imgWidth': imgWidth,
        'imgHeight': imgHeight,
      };
      print(
          'OverlayService.show: invoking method channel with args keys=${args.keys.toList()}');

      final bool shown =
          await _channel.invokeMethod('showTranslationOverlay', args);
      print('OverlayService.show: result=$shown');
      return shown;
    } on PlatformException catch (e) {
      print('Error showing translation overlay: ${e.message}');
      return false;
    } catch (e) {
      print('Unexpected error showing translation overlay: $e');
      return false;
    }
  }

  // Hide all overlays
  Future<bool> hideTranslationOverlay() async {
    try {
      print('OverlayService.hide: invoking hideTranslationOverlay');
      final bool hidden = await _channel.invokeMethod('hideTranslationOverlay');
      print('OverlayService.hide: result=$hidden');
      return hidden;
    } on PlatformException catch (e) {
      print('Error hiding translation overlay: ${e.message}');
      return false;
    } catch (e) {
      print('Unexpected error hiding translation overlay: $e');
      return false;
    }
  }

  // Hide a single overlay box by id, leaving the others on screen — used to
  // clear just the boxes that disappeared between capture ticks instead of
  // tearing down and rebuilding everything on every change.
  Future<bool> hideTranslationOverlayById(int id) async {
    try {
      final bool hidden =
          await _channel.invokeMethod('hideTranslationOverlayById', {'id': id});
      return hidden;
    } on PlatformException catch (e) {
      print('Error hiding translation overlay $id: ${e.message}');
      return false;
    } catch (e) {
      print('Unexpected error hiding translation overlay $id: $e');
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

  // Show a native toast message
  Future<void> showToast(String message) async {
    try {
      await _channel.invokeMethod('showToast', {'text': message});
    } on PlatformException catch (e) {
      print('Error showing toast: ${e.message}');
    }
  }
}

/// Completes [resumed] on the first `resumed` that follows a
/// paused/inactive/hidden state. The `resumed` we are already in when the
/// permission dialog closes must not count.
@visibleForTesting
class ResumeAfterLeavingObserver with WidgetsBindingObserver {
  final Completer<void> _completer = Completer<void>();
  bool _left = false;

  Future<void> get resumed => _completer.future;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_left && !_completer.isCompleted) _completer.complete();
    } else {
      _left = true;
    }
  }
}
