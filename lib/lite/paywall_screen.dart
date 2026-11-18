import 'package:flutter/material.dart';
import 'package:screen_translate/l10n/app_localizations.dart';

import 'lite_gate.dart';
import 'pro_entitlement.dart';

/// Lite paywall: Unlock Pro (Play's price) and Restore purchase.
///
/// With only the one-time unlock on offer it is a single "Unlock Pro · price"
/// button. Once Remote Config offers more than that, or a subscription
/// ([ProEntitlement.offers]), it lists the plans to choose from, with the
/// first one preselected, and states the renewal terms next to the button
/// whenever the chosen plan renews.
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
  String? _selectedId;

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
    final offers = e.offers;
    final showPlans =
        offers.length > 1 || offers.any((p) => ProEntitlement.isSubscription(p.id));
    // Keep the choice while it is still on offer; otherwise the first plan.
    final selectedId = offers.any((p) => p.id == _selectedId)
        ? _selectedId!
        : (offers.isEmpty ? ProEntitlement.productId : offers.first.id);
    final renews = showPlans && ProEntitlement.isSubscription(selectedId);
    final canBuy = e.productFor(selectedId) != null && !e.purchasePending;

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
              Text(showPlans ? l.paywall_body_plans(gate.dailyLimit) : l.paywall_body(gate.dailyLimit),
                  textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
              const SizedBox(height: 24),
              _benefit(Icons.all_inclusive, l.paywall_benefit_unlimited),
              _benefit(Icons.check_circle_outline,
                  renews ? l.paywall_benefit_cancel_anytime : l.paywall_benefit_once),
              const SizedBox(height: 24),
              if (showPlans) ...[
                for (final offer in offers)
                  _planTile(theme, l, offer.id, offer.price, selected: offer.id == selectedId),
                const SizedBox(height: 12),
              ],
              FilledButton(
                key: const Key('paywall_unlock'),
                onPressed: canBuy ? () => gate.startPurchase(selectedId) : null,
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: e.purchasePending
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(showPlans
                        ? l.paywall_continue
                        : (price != null ? l.paywall_unlock_button(price) : l.paywall_unlock_button_no_price)),
              ),
              if (renews) ...[
                const SizedBox(height: 8),
                Text(l.paywall_subscription_terms,
                    key: const Key('paywall_terms'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall),
              ],
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

  static String _planName(AppLocalizations l, String id) => switch (id) {
        ProEntitlement.yearlyId => l.paywall_plan_yearly,
        ProEntitlement.monthlyId => l.paywall_plan_monthly,
        _ => l.paywall_plan_lifetime,
      };

  static String _planPrice(AppLocalizations l, String id, String price) => switch (id) {
        ProEntitlement.yearlyId => l.paywall_price_per_year(price),
        ProEntitlement.monthlyId => l.paywall_price_per_month(price),
        _ => l.paywall_price_once(price),
      };

  Widget _planTile(ThemeData theme, AppLocalizations l, String id, String price,
      {required bool selected}) {
    final color = selected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Semantics(
        selected: selected,
        button: true,
        child: InkWell(
          key: Key('paywall_plan_$id'),
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _selectedId = id),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: color, width: selected ? 2 : 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              Icon(selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: color),
              const SizedBox(width: 12),
              Expanded(child: Text(_planName(l, id), style: theme.textTheme.titleMedium)),
              const SizedBox(width: 12),
              Flexible(
                child: Text(_planPrice(l, id, price),
                    textAlign: TextAlign.end, style: theme.textTheme.bodyLarge),
              ),
            ]),
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
