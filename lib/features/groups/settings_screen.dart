import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../app/demo_session.dart';
import '../../ui/app_theme.dart';

const _themeLabels = {
  ThemeMode.system: 'System',
  ThemeMode.light: 'Light',
  ThemeMode.dark: 'Dark',
};

const _languageLabels = {'en': 'English', 'tr': 'Türkçe'};

/// 22 · Settings, opened from the Profile gear.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<T?> _pick<T>(
    BuildContext context, {
    required String title,
    required Map<T, String> options,
    required T selected,
    String? note,
  }) {
    return showDialog<T>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(title),
        children: [
          for (final entry in options.entries)
            ListTile(
              title: Text(entry.value),
              selected: entry.key == selected,
              trailing: entry.key == selected
                  ? const Icon(Icons.check, size: 20)
                  : null,
              onTap: () => Navigator.pop(dialogContext, entry.key),
            ),
          if (note != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.sm,
                AppSpacing.xl,
                0,
              ),
              child: Text(
                note,
                style: Theme.of(dialogContext).textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _chooseTheme(BuildContext context) async {
    final session = context.read<DemoSession>();
    final mode = await _pick(
      context,
      title: 'Theme',
      options: _themeLabels,
      selected: session.themeMode,
    );
    if (mode != null) session.setThemeMode(mode);
  }

  Future<void> _chooseLanguage(BuildContext context) async {
    final session = context.read<DemoSession>();
    final code = await _pick(
      context,
      title: 'Language',
      options: _languageLabels,
      selected: session.languageCode,
      note:
          'Your choice is saved on this device. In this demo, app text '
          'stays in English.',
    );
    if (code != null) session.setLanguageCode(code);
  }

  void _about(BuildContext context, String title, String body) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<DemoSession>();
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
          children: [
            const _SectionHeader('PREFERENCES'),
            _SettingsRow(
              icon: Icons.brightness_6_outlined,
              title: 'Theme',
              value: _themeLabels[session.themeMode]!,
              onTap: () => _chooseTheme(context),
            ),
            _SettingsRow(
              icon: Icons.language,
              title: 'Language',
              value:
                  _languageLabels[session.languageCode] ?? session.languageCode,
              onTap: () => _chooseLanguage(context),
            ),
            _Divided(
              child: SwitchListTile(
                secondary: const Icon(Icons.notifications_none),
                title: const Text('Notifications'),
                value: session.notificationsEnabled,
                onChanged: context.read<DemoSession>().setNotificationsEnabled,
              ),
            ),
            const _SectionHeader('ABOUT'),
            _SettingsRow(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              onTap: () => _about(
                context,
                'Privacy Policy',
                'This Step 2.2 demo keeps all trips, groups and settings in '
                    'memory on this device. Nothing is sent to a server, and '
                    'data resets when the app restarts.',
              ),
            ),
            _SettingsRow(
              icon: Icons.help_outline,
              title: 'Support',
              onTap: () => _about(
                context,
                'Support',
                'TripMate is built by CS310 Group 39 at Sabancı University. '
                    'For help with the demo, contact a team member.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.xl,
        AppSpacing.page,
        AppSpacing.sm,
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _Divided extends StatelessWidget {
  const _Divided({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      border: Border(
        bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
    ),
    child: child,
  );
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.value,
  });

  final IconData icon;
  final String title;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _Divided(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (value != null)
              Text(
                value!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
