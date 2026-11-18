import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../app/step22_routes.dart';
import '../../data/demo_models.dart';
import '../../data/places_store.dart';
import '../../data/trip_store.dart';
import '../../ui/app_theme.dart';
import 'discover_common.dart';

class ItineraryScreen extends StatefulWidget {
  const ItineraryScreen({super.key, required this.args});

  final CityStopArgs args;

  @override
  State<ItineraryScreen> createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends State<ItineraryScreen> {
  DateTime? _day;

  String get _tripId => widget.args.tripId;
  String get _stopId => widget.args.stopId;

  bool _stopExists() =>
      findStop(context.read<TripStore>().byId(_tripId), _stopId) != null;

  Future<void> _editStop() async {
    await Navigator.pushNamed<void>(
      context,
      AppRoute.editCityStop,
      arguments: CityEditArgs(_tripId, _stopId),
    );
    if (!mounted || _stopExists()) return;
    if (ModalRoute.of(context)?.isCurrent ?? false) Navigator.pop(context);
  }

  Future<void> _addActivity(DateTime day) async {
    final result = await Navigator.pushNamed<Object?>(
      context,
      AppRoute.addActivity,
      arguments: ActivityArgs(_tripId, _stopId, day),
    );
    if (mounted && result is DateTime) {
      setState(() => _day = DateUtils.dateOnly(result));
    }
  }

  Future<void> _removeActivity(Activity activity) async {
    if (await confirmRemoval(context, activity.title) && mounted) {
      context.read<PlacesStore>().removeActivity(activity.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = context.select((TripStore store) => store.byId(_tripId));
    final stop = findStop(trip, _stopId);
    if (stop == null) {
      return const UnavailableScreen(
        message: 'This city stop is no longer part of the trip.',
      );
    }

    final days = stopDays(stop);
    final selected = days.contains(_day) ? _day! : days.first;
    final activities = context.watch<PlacesStore>().activitiesFor(
      _tripId,
      _stopId,
      selected,
    );
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(stop.name, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'Edit city stop',
            onPressed: _editStop,
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.lg,
            AppSpacing.page,
            96,
          ),
          children: [
            _HotelBox(stop: stop),
            const SizedBox(height: AppSpacing.lg),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<DateTime>(
                showSelectedIcon: false,
                segments: [
                  for (final (index, day) in days.indexed)
                    ButtonSegment(
                      value: day,
                      label: Text('Day ${index + 1}'),
                      tooltip: DiscoverFormat.shortDate(day),
                    ),
                ],
                selected: {selected},
                onSelectionChanged: (selection) =>
                    setState(() => _day = selection.first),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              DiscoverFormat.shortDate(selected),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (activities.isEmpty)
              const DiscoverEmptyState(
                message: 'No activities for this day yet. Add one with +.',
              )
            else
              for (final activity in activities)
                _ActivityCard(
                  key: ValueKey(activity.id),
                  activity: activity,
                  onRemove: () => _removeActivity(activity),
                ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed<void>(
                context,
                AppRoute.nearby,
                arguments: CityStopArgs(_tripId, _stopId),
              ),
              icon: const Icon(Icons.near_me_outlined),
              label: const Text('Nearby places'),
            ),
          ],
        ),
      ),
      floatingActionButton: SizedBox.square(
        dimension: 48,
        child: FloatingActionButton(
          tooltip: 'Add activity',
          onPressed: () => _addActivity(selected),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class _HotelBox extends StatelessWidget {
  const _HotelBox({required this.stop});

  final CityStop stop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meta = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.hotel_outlined, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stop.hotelName.isEmpty ? 'No hotel yet' : stop.hotelName,
                  style: theme.textTheme.titleSmall,
                ),
                if (stop.hotelAddress.isNotEmpty)
                  Text(stop.hotelAddress, style: meta),
                Text(
                  DiscoverFormat.dateRange(stop.arrival, stop.departure),
                  style: meta,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    super.key,
    required this.activity,
    required this.onRemove,
  });

  final Activity activity;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meta = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final location = activity.location;
    final note = activity.note;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.only(left: AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: SizedBox(
                  width: 48,
                  child: Text(
                    DiscoverFormat.time(activity.start),
                    style: theme.textTheme.labelLarge,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(activity.title, style: theme.textTheme.titleSmall),
                      if (location != null) Text(location, style: meta),
                      if (note != null) Text(note, style: meta),
                    ],
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Remove ${activity.title}',
                onPressed: onRemove,
                icon: const Icon(Icons.close, size: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
