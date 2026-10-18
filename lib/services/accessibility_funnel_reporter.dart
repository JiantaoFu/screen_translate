import 'package:flutter/services.dart';

import 'activation_tracker.dart';

/// Forwards the native accessibility explainer's outcome to analytics.
///
/// The explainer (AccessibilityPermissionActivity) is shown natively on
/// first launch, before or without Dart being in front, so native only
/// records what happened (AccessibilityFunnelStore) and Dart picks it up on
/// app start and every resume: `accessibility_prompt_shown` once the prompt
/// was shown, and `accessibility_permission_result` once the user has left
/// it (and come back from Settings, if they went there). Native clears what
/// it hands over, so each is sent once.
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
