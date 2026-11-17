import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../data/demo_models.dart';
import '../data/group_store.dart';
import '../data/trip_store.dart';
import '../ui/app_theme.dart';
import '../ui/app_widgets.dart';
import 'demo_session.dart';
import 'step22_routes.dart';
import 'trip_actions.dart';

class MyTripsScreen extends StatefulWidget {
  const MyTripsScreen({super.key});

  @override
  State<MyTripsScreen> createState() => _MyTripsScreenState();
}

class _MyTripsScreenState extends State<MyTripsScreen> {
  var _openingCreateTrip = false;

  Future<void> _createTrip() async {
    if (_openingCreateTrip) return;
    _openingCreateTrip = true;
    try {
      final tripId = await Navigator.pushNamed<String>(
        context,
        AppRoute.createTrip,
      );
      if (!mounted || tripId == null) return;
      if (context.read<TripStore>().byId(tripId) == null) return;
      await Navigator.pushNamed<void>(
        context,
        AppRoute.tripDetail,
        arguments: tripId,
      );
    } finally {
      _openingCreateTrip = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.select(
      (DemoSession session) => session.currentUserId,
    );
    final user = demoUsers[userId];
    final firstName = user?.displayName.split(' ').first;
    final store = context.watch<TripStore>();
    final groups = context.watch<GroupStore>();
    final upcoming = <Trip>[];
    final past = <Trip>[];
    for (final trip in store.trips) {
      final end = DateUtils.dateOnly(trip.end);
      (end.isBefore(store.demoToday) ? past : upcoming).add(trip);
    }
    final count = upcoming.length;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Trips'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: IconButton(
              tooltip: 'Open Profile',
              onPressed: () =>
                  context.read<DemoSession>().selectTab(AppMainTab.profile),
              icon: CircleAvatar(
                radius: 15,
                backgroundColor: theme.colorScheme.surface,
                foregroundColor: theme.colorScheme.onSurface,
                child: Text(firstName?.characters.first ?? 'A'),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        key: const PageStorageKey('my-trips-list'),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.lg,
          AppSpacing.page,
          88,
        ),
        children: [
          Text(
            firstName == null ? 'Hi!' : 'Hi, $firstName!',
            style: theme.textTheme.headlineSmall?.copyWith(fontSize: 21),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '$count upcoming ${count == 1 ? 'trip' : 'trips'}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final trip in upcoming)
            _TripCard(
              key: ValueKey(trip.id),
              trip: trip,
              memberCount: groups.byId(trip.groupId)?.memberIds.length,
              isPast: false,
            ),
          if (past.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'PAST TRIPS',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final trip in past)
              _TripCard(
                key: ValueKey(trip.id),
                trip: trip,
                memberCount: groups.byId(trip.groupId)?.memberIds.length,
                isPast: true,
              ),
          ],
        ],
      ),
      floatingActionButton: SizedBox.square(
        dimension: 48,
        child: FloatingActionButton(
          tooltip: 'Create trip',
          onPressed: _createTrip,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({
    super.key,
    required this.trip,
    required this.memberCount,
    required this.isPast,
  });

  final Trip trip;
  final int? memberCount;
  final bool isPast;

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  String _dateLabel() {
    final start = trip.start;
    final end = trip.end;
    final startMonth = _months[start.month - 1];
    final endMonth = _months[end.month - 1];
    if (start.year != end.year) {
      return '${start.day} $startMonth ${start.year}–${end.day} $endMonth ${end.year}';
    }
    if (start.month != end.month) {
      return '${start.day} $startMonth–${end.day} $endMonth';
    }
    if (isPast) return startMonth;
    if (start.day == end.day) return '${start.day} $startMonth';
    return '${start.day}–${end.day} $startMonth';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meta = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final count = memberCount;
    final details = count == null
        ? _dateLabel()
        : '${_dateLabel()} · $count ${count == 1 ? 'member' : 'members'}';
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                button: true,
                child: InkWell(
                  onTap: () => Navigator.pushNamed<void>(
                    context,
                    AppRoute.tripDetail,
                    arguments: trip.id,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        SizedBox.square(
                          dimension: 62,
                          child: AppImage(
                            asset: trip.coverAsset ?? AppAssets.tripCover,
                            imageUrl: trip.imageUrl,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                trip.title,
                                style: theme.textTheme.titleSmall,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (trip.stops.isNotEmpty)
                                Text(
                                  trip.stops
                                      .map((stop) => stop.name)
                                      .join(' → '),
                                  style: meta,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              Text(details, style: meta),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Remove ${trip.title}',
              onPressed: () => confirmTripRemoval(context, trip),
              icon: const Icon(Icons.close, size: 16),
            ),
          ],
        ),
      ),
    );
  }
}
