import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../app/demo_session.dart';
import '../../app/step22_routes.dart';
import '../../data/demo_models.dart';
import '../../data/group_store.dart';
import '../../data/places_store.dart';
import '../../data/trip_store.dart';
import '../../ui/app_theme.dart';
import '../trips/trip_format.dart';

/// 21 · Profile root tab: the demo user, simple counts and preferences.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<DemoSession>();
    final userId = session.currentUserId;
    final user = demoUsers[userId];
    final groups = [
      for (final group in context.watch<GroupStore>().visibleGroups)
        if (group.memberIds.contains(userId)) group,
    ];
    final groupIds = {for (final group in groups) group.id};
    final tripIds = {
      for (final trip in context.watch<TripStore>().trips)
        if (groupIds.contains(trip.groupId)) trip.id,
    };
    final logCount = context.watch<PlacesStore>().logCountForTrips(tripIds);
    final currency = session.defaultCurrencyCode;
    final currencies = [
      ...TripFormat.currencies,
      if (!TripFormat.currencies.contains(currency)) currency,
    ];
    final theme = Theme.of(context);
    final name = user?.displayName ?? 'TripMate user';
    final initial = name.isEmpty ? '?' : name.characters.first.toUpperCase();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: () =>
                Navigator.pushNamed<void>(context, AppRoute.settings),
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.xl,
            AppSpacing.page,
            AppSpacing.xxl,
          ),
          children: [
            Center(
              child: Container(
                width: 88,
                height: 88,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.surfaceContainerHighest,
                  border: Border.all(color: theme.colorScheme.outline),
                ),
                child: Text(
                  initial,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              name,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (user != null)
              Text(
                '@${user.username} · ${user.email}',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Count(value: tripIds.length, label: 'trips'),
                _Count(value: groups.length, label: 'groups'),
                _Count(value: logCount, label: 'place logs'),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            DropdownButtonFormField<String>(
              key: const Key('profile-currency'),
              initialValue: currency,
              decoration: const InputDecoration(
                labelText: 'Default currency',
                helperText: 'Used as the starting currency of new trips.',
              ),
              items: [
                for (final code in currencies)
                  DropdownMenuItem(value: code, child: Text(code)),
              ],
              onChanged: (code) {
                if (code != null) {
                  context.read<DemoSession>().setDefaultCurrencyCode(code);
                }
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton(
              onPressed: () => AppRoute.logOut(context),
              child: const Text('Log Out'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        children: [
          Text(
            '$value',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
