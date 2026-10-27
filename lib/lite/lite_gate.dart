import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_flavor.dart';
import '../services/firebase_analytics_service.dart';
import '../services/firebase_remote_config_service.dart';
import 'daily_translation_quota.dart';
import 'pro_entitlement.dart';

typedef LiteEventLogger = Future<void> Function(String name, Map<String, Object> params);

/// Lite flavor's monetization rules in one place; a no-op in the paid app.
///
/// - [mayStartTranslation] gates new attempts (Start, image translation).
///   It only says no once today's free translations are used up, so the
///   paywall never appears at launch or before the user has seen a result.
/// - [recordTranslationSuccess] counts a success; the one that uses up the
///   last free translation sets [paywallPending], and the UI shows the
///   paywall right after (on return to the app for live sessions).
/// - Analytics: translation_success, free_limit_hit, paywall_shown,
///   pro_purchased (with remaining_free / daily_limit where they apply),
///   pro_revoked (Play no longer reports pro_unlock, e.g. refunded).
class LiteGate extends ChangeNotifier {
  static const evTranslationSuccess = 'translation_success';
  static const evFreeLimitHit = 'free_limit_hit';
  static const evPaywallShown = 'paywall_shown';
  static const evProPurchased = 'pro_purchased';
  static const evProRevoked = 'pro_revoked';

  /// The app-wide gate; null until [initForApp] ran (and always in paid).
  static final ValueNotifier<LiteGate?> current = ValueNotifier<LiteGate?>(null);
  static LiteGate? get instance => current.value;

  final bool enabled;
  final DailyTranslationQuota quota;
  final ProEntitlement entitlement;
  final LiteEventLogger _log;
  bool _paywallPending = false;

  LiteGate({
    required this.enabled,
    required this.quota,
    required this.entitlement,
    LiteEventLogger? logEvent,
  }) : _log = logEvent ?? ((name, params) => FirebaseAnalyticsService().logEvent(name, params)) {
    entitlement.addListener(notifyListeners);
  }

  /// Builds [instance] for the lite flavor and starts billing (restore).
  static Future<void> initForApp() async {
    if (!AppFlavorConfig.isLite || current.value != null) return;
    final prefs = await SharedPreferences.getInstance();
    late final LiteGate gate;
    final entitlement = ProEntitlement(
      prefs,
      onPurchased: (p) => gate._onPurchased(),
      onRevoked: () => gate._onRevoked(),
    );
    gate = LiteGate(
      enabled: true,
      quota: DailyTranslationQuota(prefs,
          limit: FirebaseRemoteConfigService().getLiteDailyFreeTranslations),
      entitlement: entitlement,
    );
    current.value = gate;
    await entitlement.init();
  }

  /// Waits for the lite gate to be built, and returns [instance].
  ///
  /// [initForApp] runs just after runApp and needs a SharedPreferences read
  /// before the gate exists. A share-into-the-app on a cold start resolves
  /// inside that window, so anything gating a translation attempt waits here
  /// instead of reading a missing gate as "allow" and letting the attempt
  /// through for free. Returns null straight away in the paid app, and falls
  /// back to whatever exists if the gate never arrives, so a broken init
  /// can't make the app unusable.
  static Future<LiteGate?> waitForInstance({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (!AppFlavorConfig.isLite || current.value != null) return current.value;
    final built = Completer<LiteGate?>();
    void onChange() {
      if (current.value != null && !built.isCompleted) built.complete(current.value);
    }

    current.addListener(onChange);
    try {
      return await built.future.timeout(timeout, onTimeout: () => current.value);
    } finally {
      current.removeListener(onChange);
    }
  }

  bool get isPro => entitlement.isPro;
  int get dailyLimit => quota.dailyLimit;
  int get remainingFree => quota.remaining;
  bool get paywallPending => _paywallPending;

  Map<String, Object> get _quotaParams => {
        'remaining_free': quota.remaining,
        'daily_limit': quota.dailyLimit,
      };

  /// Whether a new translation attempt may go ahead. Logs free_limit_hit
  /// when it may not; the caller then shows the paywall.
  bool mayStartTranslation({required String kind}) {
    if (!enabled || isPro || quota.canTranslate(isPro: false)) return true;
    _log(evFreeLimitHit, {..._quotaParams, 'kind': kind});
    return false;
  }

  /// Counts one successful translation (`live` session or `image`).
  Future<QuotaUse?> recordTranslationSuccess({required String kind}) async {
    if (!enabled) return null;
    final use = await quota.recordSuccess(isPro: isPro);
    _log(evTranslationSuccess, {
      'remaining_free': use.remaining,
      'daily_limit': use.dailyLimit,
      'is_pro': isPro ? 1 : 0,
      'kind': kind,
    });
    if (use.justExhausted) {
      _paywallPending = true;
      notifyListeners();
    }
    return use;
  }

  /// Returns true (once) when the paywall is due after the last free success.
  bool takePendingPaywall() {
    if (!_paywallPending || isPro) {
      _paywallPending = false;
      return false;
    }
    _paywallPending = false;
    return true;
  }

  /// [trigger]: limit_reached (just used the last free one), limit_hit
  /// (tried to start with none left), or home (user opened it).
  void paywallShown(String trigger) {
    _log(evPaywallShown, {..._quotaParams, 'trigger': trigger});
  }

  void _onPurchased() {
    _paywallPending = false;
    _log(evProPurchased, {
      ..._quotaParams,
      'product_id': ProEntitlement.productId,
      'price': entitlement.price ?? '',
    });
  }

  void _onRevoked() {
    _log(evProRevoked, {'product_id': ProEntitlement.productId});
  }

  @visibleForTesting
  void debugOnPurchased() => _onPurchased();

  @visibleForTesting
  void debugOnRevoked() => _onRevoked();

  @override
  void dispose() {
    entitlement.removeListener(notifyListeners);
    super.dispose();
  }
}
