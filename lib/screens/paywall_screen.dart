import 'package:material_ui/material_ui.dart';

import '../app_services.dart';
import '../l10n/app_localizations.dart';
import '../services/purchase_service.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({
    super.key,
    required this.services,
    required this.source,
  });

  final AppServices services;

  /// Where the paywall was opened from (analytics).
  final String source;

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  AppServices get s => widget.services;
  late final Future<List<Plan>> _plans = s.purchases.plans();
  Plan? _chosen;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    s.analytics.log('paywall_view', {'source': widget.source});
  }

  void _toast(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _buy(L10n t, Plan plan) async {
    setState(() => _busy = true);
    final r = await s.purchases.buy(plan);
    if (!mounted) return;
    setState(() => _busy = false);
    switch (r) {
      case BuyResult.success:
        s.analytics.log('purchase', {'plan': plan.id, 'source': widget.source});
        _toast(t.purchaseSuccess);
        Navigator.of(context).pop();
      case BuyResult.error:
        _toast(t.purchaseError);
      case BuyResult.cancelled:
        break;
    }
  }

  Future<void> _restore(L10n t) async {
    setState(() => _busy = true);
    final ok = await s.purchases.restore();
    if (!mounted) return;
    setState(() => _busy = false);
    _toast(ok ? t.restoreSuccess : t.restoreNone);
    if (ok) Navigator.of(context).pop();
  }

  String _planTitle(L10n t, Plan p) => switch (p.period) {
    PlanPeriod.yearly => t.yearly,
    PlanPeriod.monthly => t.monthly,
    PlanPeriod.other => p.id,
  };

  String _planPrice(L10n t, Plan p) => switch (p.period) {
    PlanPeriod.yearly => t.pricePerYear(p.price),
    PlanPeriod.monthly => t.pricePerMonth(p.price),
    PlanPeriod.other => p.price,
  };

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.premium)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Icon(
              Icons.workspace_premium,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              t.paywallTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              t.paywallSubtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            for (final b in [t.benefitAll, t.benefitNew, t.benefitReview])
              ListTile(
                leading: Icon(Icons.check_circle, color: Colors.green.shade600),
                title: Text(b),
              ),
            const SizedBox(height: 16),
            if (s.isPremium)
              Text(
                t.alreadyPremium,
                key: const Key('already_premium'),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              )
            else
              FutureBuilder<List<Plan>>(
                future: _plans,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final plans = snap.data ?? const [];
                  if (plans.isEmpty) {
                    return Text(
                      t.billingUnavailable,
                      key: const Key('billing_unavailable'),
                      textAlign: TextAlign.center,
                    );
                  }
                  final chosen = _chosen ?? plans.first;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      RadioGroup<String>(
                        groupValue: chosen.id,
                        onChanged: (id) => setState(
                          () => _chosen = plans.firstWhere((p) => p.id == id),
                        ),
                        child: Column(
                          children: [
                            for (final p in plans)
                              Card(
                                child: RadioListTile<String>(
                                  key: Key('plan_${p.id}'),
                                  value: p.id,
                                  title: Text(_planTitle(t, p)),
                                  subtitle: Text(_planPrice(t, p)),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        key: const Key('subscribe'),
                        onPressed: _busy ? null : () => _buy(t, chosen),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(t.subscribe),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        t.cancelAnytime,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  );
                },
              ),
            const SizedBox(height: 16),
            TextButton(
              key: const Key('paywall_restore'),
              onPressed: _busy ? null : () => _restore(t),
              child: Text(t.restorePurchases),
            ),
          ],
        ),
      ),
    );
  }
}
