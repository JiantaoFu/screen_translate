import 'package:flutter/material.dart';
import 'package:screen_translate/l10n/app_localizations.dart';

import 'lite_gate.dart';

/// Lite paywall: Unlock Pro (Play's price) and Restore purchase.
///
/// Shown right after the success that used up the last free translation of
/// the day, or when the user tries to translate with none left. Closes
/// itself once Pro is unlocked.
class PaywallScreen extends StatefulWidget {
  final LiteGate gate;
  final String trigger;

  const PaywallScreen({super.key, required this.gate, required this.trigger});

  /// Pushes the paywall (logs paywall_shown); completes when it closes.
  static Future<void> show(BuildContext context, LiteGate gate, {required String trigger}) {
    gate.paywallShown(trigger);
    return Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => PaywallScreen(gate: gate, trigger: trigger),
    ));
  }

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    widget.gate.addListener(_onChange);
    final e = widget.gate.entitlement;
    if (e.storeAvailable && e.product == null) e.loadProduct();
  }

  @override
  void dispose() {
    widget.gate.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (!mounted) return;
    if (widget.gate.isPro && !_closing) {
      _closing = true;
      final messenger = ScaffoldMessenger.maybeOf(context);
      final text = AppLocalizations.of(context)!.paywall_pro_unlocked;
      Navigator.of(context).maybePop();
      messenger?.showSnackBar(SnackBar(content: Text(text)));
      return;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final gate = widget.gate;
    final e = gate.entitlement;
    final theme = Theme.of(context);
    final price = e.price;
    final canBuy = e.product != null && !e.purchasePending;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          key: const Key('paywall_close'),
          icon: const Icon(Icons.close),
          tooltip: l.paywall_not_now,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.workspace_premium, size: 72, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(l.paywall_title,
                  textAlign: TextAlign.center, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 12),
              Text(l.paywall_body(gate.dailyLimit),
                  textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
              const SizedBox(height: 24),
              _benefit(Icons.all_inclusive, l.paywall_benefit_unlimited),
              _benefit(Icons.check_circle_outline, l.paywall_benefit_once),
              const SizedBox(height: 24),
              FilledButton(
                key: const Key('paywall_unlock'),
                onPressed: canBuy ? () => e.buy() : null,
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: e.purchasePending
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(price != null ? l.paywall_unlock_button(price) : l.paywall_unlock_button_no_price),
              ),
              if (!e.storeAvailable && e.initialized) ...[
                const SizedBox(height: 8),
                Text(l.paywall_store_unavailable,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
              ],
              const SizedBox(height: 8),
              TextButton(
                key: const Key('paywall_restore'),
                onPressed: e.storeAvailable ? () => e.restore() : null,
                child: Text(l.paywall_restore),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: Text(l.paywall_not_now),
              ),
              const SizedBox(height: 8),
              Text(l.paywall_reset_hint,
                  textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }

  Widget _benefit(IconData icon, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ]),
      );
}
