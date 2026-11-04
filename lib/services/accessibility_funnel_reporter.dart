import 'package:flutter/services.dart';

import 'activation_tracker.dart';

/// Shows the native accessibility explainer, and forwards its outcome to
/// analytics.
///
/// The explainer is a native activity (AccessibilityPermissionActivity),
/// and the user can leave it for the system Settings and come back, so Dart
/// is not in front for its outcome. Native records what happened
/// (AccessibilityFunnelStore) and Dart picks it up on app start and every
/// resume: `accessibility_prompt_shown` once the prompt was shown, and
/// `accessibility_permission_result` once the user has left it (and come
/// back from Settings, if they went there). Native clears what it hands
/// over, so each is sent once.
///
/// Dart also decides when to show it (see [maybeExplain]); it used to be
/// shown from ScreenCaptureService.initialize() on first launch.
class AccessibilityFunnelReporter {
  AccessibilityFunnelReporter({MethodChannel? channel, ActivationTracker? tracker})
      : _channel = channel ?? defaultChannel,
        _tracker = tracker ?? ActivationTracker.instance;

  static const defaultChannel = MethodChannel('com.lomoware.screen_translate/accessibility');
  static final AccessibilityFunnelReporter instance = AccessibilityFunnelReporter();

  final MethodChannel _channel;
  final ActivationTracker _tracker;
  Future<void>? _inFlight;

  /// Safe to call often: concurrent calls share one native round trip, and
  /// a missing or failing native side is ignored.
  Future<void> report() => _inFlight ??= _report().whenComplete(() => _inFlight = null);

  /// Asks native to explain the accessibility service, if it is time to.
  ///
  /// True if a dialog was actually launched, so the caller knows this
  /// resume is taken. Only once a translation has been shown: the explainer
  /// used to run from ScreenCaptureService.initialize(), which meant a
  /// ~250-word disclosure about an optional service was the first thing a
  /// new buyer saw, before the app had translated a word. Native owns the
  /// rest of the conditions (once per install, not already enabled, never
  /// in lite), so there is no second copy of that state here.
  Future<bool> maybeExplain() async {
    if (!await _tracker.firstTranslationEverShown()) return false;
    try {
      return await _channel.invokeMethod<bool>('showAccessibilityExplainer') ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _report() async {
    try {
      final state = await _channel.invokeMapMethod<String, Object?>('takeAccessibilityFunnel');
      if (state == null) return;
      if (state['promptShown'] == true) _tracker.accessibilityPromptShown();
      final result = state['result'];
      if (result is Map) {
        _tracker.accessibilityPermissionResult(
          enabled: result['enabled'] == true,
          action: result['action'] is String ? result['action'] as String : 'unknown',
        );
      }
    } catch (_) {
      // MissingPluginException off Android / in tests, PlatformException:
      // analytics must never break startup or resume.
    }
  }
}
