import 'package:material_ui/material_ui.dart';

import '../app_services.dart';
import '../l10n/app_localizations.dart';
import 'paywall_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  AppServices get s => widget.services;
  bool _busy = false;

  Future<void> _restore(L10n t) async {
    setState(() => _busy = true);
    final ok = await s.purchases.restore();
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? t.restoreSuccess : t.restoreNone)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final theme = Theme.of(context);
    final current = Localizations.localeOf(context).languageCode;
    return Scaffold(
      appBar: AppBar(title: Text(t.settings)),
      body: ListView(
        children: [
          ListTile(
            title: Text(t.language, style: theme.textTheme.titleSmall),
            subtitle: kNativeCheckedLanguages.contains(current)
                ? null
                : Text('${t.machineTranslation} ${t.explanationLanguageNote}'),
          ),
          RadioGroup<String>(
            groupValue: s.language.value ?? '',
            onChanged: (v) => s.setLanguage(v == '' ? null : v),
            child: Column(
              children: [
                RadioListTile<String>(
                  key: const Key('lang_system'),
                  value: '',
                  title: Text(t.systemLanguage),
                ),
                for (final e in kSupportedLanguages.entries)
                  RadioListTile<String>(
                    key: Key('lang_${e.key}'),
                    value: e.key,
                    title: Text(e.value),
                  ),
              ],
            ),
          ),
          const Divider(),
          ValueListenableBuilder<bool>(
            valueListenable: s.furigana,
            builder: (context, on, _) => SwitchListTile(
              key: const Key('furigana_switch'),
              title: Text(t.furigana),
              subtitle: Text(t.furiganaHint),
              value: on,
              onChanged: s.setFurigana,
            ),
          ),
          const Divider(),
          ValueListenableBuilder<bool>(
            valueListenable: s.purchases.isPremium,
            builder: (context, premium, _) => ListTile(
              key: const Key('premium_tile'),
              leading: const Icon(Icons.workspace_premium),
              title: Text(t.premium),
              subtitle: Text(premium ? t.premiumActive : t.premiumInactive),
              trailing: premium ? null : const Icon(Icons.chevron_right),
              onTap: premium
                  ? null
                  : () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            PaywallScreen(services: s, source: 'settings'),
                      ),
                    ),
            ),
          ),
          ListTile(
            key: const Key('settings_restore'),
            leading: const Icon(Icons.restore),
            title: Text(t.restorePurchases),
            enabled: !_busy,
            onTap: () => _restore(t),
          ),
        ],
      ),
    );
  }
}
