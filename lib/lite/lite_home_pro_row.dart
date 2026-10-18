import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'lite_gate.dart';

/// Lite home screen: today's remaining free translations and an
/// "Unlock Pro · <price>" button.
///
/// The price is Play's localized [ProEntitlement.price] (ProductDetails of
/// pro_unlock), never a hardcoded amount; until it is loaded, or when the
/// store is unavailable, the button reads just "Unlock Pro". Nothing is shown
/// once Pro is owned. Both buttons call [onOpenPaywall] (the existing
/// paywall, which runs the purchase) with a trigger for analytics.
class LiteHomeProRow extends StatelessWidget {
  final LiteGate? gate;
  final void Function(LiteGate gate, String trigger) onOpenPaywall;

  const LiteHomeProRow({super.key, required this.gate, required this.onOpenPaywall});

  @override
  Widget build(BuildContext context) {
    final gate = this.gate;
    if (gate == null || gate.isPro) return const SizedBox.shrink();
    final l = AppLocalizations.of(context)!;
    final price = gate.entitlement.price;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 4,
        children: [
          TextButton.icon(
            key: const Key('lite_remaining'),
            icon: const Icon(Icons.workspace_premium, size: 18),
            label: Text(l.lite_remaining_today(gate.remainingFree)),
            onPressed: () => onOpenPaywall(gate, 'home'),
          ),
          FilledButton.icon(
            key: const Key('lite_home_unlock'),
            icon: const Icon(Icons.lock_open, size: 18),
            label: Text(price != null && price.isNotEmpty
                ? l.paywall_unlock_button(price)
                : l.paywall_unlock_button_no_price),
            onPressed: () => onOpenPaywall(gate, 'home_unlock'),
          ),
        ],
      ),
    );
  }
}
