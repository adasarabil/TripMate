import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../app/step22_routes.dart';
import '../../data/demo_models.dart';
import '../../data/trip_store.dart';
import '../../ui/app_theme.dart';
import 'trip_format.dart';

/// 06 · Trip Detail – Route. Body only; the shared shell owns the app bar.
class RouteTab extends StatelessWidget {
  const RouteTab({super.key, required this.tripId});

  final String tripId;

  void _addCity(BuildContext context) => Navigator.pushNamed<void>(
    context,
    AppRoute.editCityStop,
    arguments: CityEditArgs(tripId),
  );

  // onReorderItem already reports the final index of the moved stop.
  void _onReorder(BuildContext context, int oldIndex, int newIndex) =>
      context.read<TripStore>().moveStop(tripId, oldIndex, newIndex);

  @override
  Widget build(BuildContext context) {
    final store = context.watch<TripStore>();
    final trip = store.byId(tripId);
    if (trip == null) return const SizedBox.shrink();
    final legs = store.legsOf(tripId);
    final summary = store.routeSummary(tripId);

    final addCity = Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: OutlinedButton.icon(
        onPressed: () => _addCity(context),
        icon: const Icon(Icons.add),
        label: const Text('Add city'),
      ),
    );

    if (trip.stops.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.page),
        children: [
          _RouteSummary(trip: trip, summary: summary),
          const SizedBox(height: AppSpacing.xxl),
          Icon(
            Icons.alt_route,
            size: 40,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No cities yet',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Add the first city of your route to start planning.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          addCity,
        ],
      );
    }

    return ReorderableListView.builder(
      key: PageStorageKey('route-$tripId'),
      buildDefaultDragHandles: false,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.lg,
        AppSpacing.page,
        AppSpacing.xxl,
      ),
      header: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: _RouteSummary(trip: trip, summary: summary),
      ),
      footer: addCity,
      itemCount: trip.stops.length,
      onReorderItem: (oldIndex, newIndex) =>
          _onReorder(context, oldIndex, newIndex),
      itemBuilder: (context, index) {
        final stop = trip.stops[index];
        return _StopItem(
          key: ValueKey(stop.id),
          trip: trip,
          stop: stop,
          index: index,
          leg: index < legs.length ? legs[index] : null,
        );
      },
    );
  }
}

class _RouteSummary extends StatelessWidget {
  const _RouteSummary({required this.trip, required this.summary});

  final Trip trip;
  final RouteCostSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = trip.stops.length;
    final meta = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final String total;
    if (summary.legCount == 0) {
      total = 'No transport legs yet';
    } else if (summary.isComplete) {
      total = TripFormat.money(summary.totalMinor, trip.currencyCode);
    } else if (summary.missingLegCount == summary.legCount) {
      total = 'Incomplete · no options yet';
    } else {
      final missing = summary.missingLegCount;
      total =
          '${TripFormat.money(summary.totalMinor, trip.currencyCode)} so far · '
          '$missing ${missing == 1 ? 'leg' : 'legs'} missing';
    }
    return Card(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$count ${count == 1 ? 'city' : 'cities'} · '
              '${TripFormat.dateRange(trip.start, trip.end)}',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text.rich(
              key: const Key('route-total'),
              TextSpan(
                children: [
                  const TextSpan(text: 'Cheapest transport total: '),
                  TextSpan(
                    text: total,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              style: meta,
            ),
          ],
        ),
      ),
    );
  }
}

class _StopItem extends StatelessWidget {
  const _StopItem({
    super.key,
    required this.trip,
    required this.stop,
    required this.index,
    required this.leg,
  });

  final Trip trip;
  final CityStop stop;
  final int index;
  final RouteLeg? leg;

  void _openItinerary(BuildContext context) => Navigator.pushNamed<void>(
    context,
    AppRoute.itinerary,
    arguments: CityStopArgs(trip.id, stop.id),
  );

  void _edit(BuildContext context) => Navigator.pushNamed<void>(
    context,
    AppRoute.editCityStop,
    arguments: CityEditArgs(trip.id, stop.id),
  );

  Future<void> _remove(BuildContext context) async {
    final store = context.read<TripStore>();
    if (await confirmTripAction(
      context,
      title: 'Remove city?',
      message:
          'Remove ${stop.name} from the route? Its transport options are '
          'removed too.',
      confirmLabel: 'Remove',
    )) {
      store.removeStop(trip.id, stop.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentLeg = leg;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              ReorderableDragStartListener(
                index: index,
                child: Tooltip(
                  message: 'Drag to reorder ${stop.name}',
                  child: const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.lg,
                    ),
                    child: Icon(Icons.drag_indicator, size: 20),
                  ),
                ),
              ),
              Expanded(
                child: Semantics(
                  button: true,
                  hint: 'Long press to edit',
                  child: InkWell(
                    onTap: () => _openItinerary(context),
                    onLongPress: () => _edit(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stop.name,
                            style: theme.textTheme.titleSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${TripFormat.dateRange(stop.arrival, stop.departure)}'
                            ' · ${stop.hotelName}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Edit ${stop.name}',
                onPressed: () => _edit(context),
                icon: const Icon(Icons.edit_outlined, size: 18),
              ),
              IconButton(
                tooltip: 'Remove ${stop.name}',
                onPressed: () => _remove(context),
                icon: const Icon(Icons.close, size: 16),
              ),
            ],
          ),
        ),
        if (currentLeg != null)
          _LegRow(trip: trip, leg: currentLeg)
        else
          const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}

class _LegRow extends StatelessWidget {
  const _LegRow({required this.trip, required this.leg});

  final Trip trip;
  final RouteLeg leg;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cheapest = leg.cheapest;
    final args = LegArgs(trip.id, leg.from.id, leg.to.id);
    final label = cheapest == null
        ? 'Add transport option'
        : '${cheapest.mode.label} · '
              '${TripFormat.money(cheapest.priceMinor, trip.currencyCode)} · '
              '${TripFormat.duration(cheapest.durationMinutes)}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Semantics(
        button: true,
        label: '${leg.from.name} to ${leg.to.name} transport',
        child: InkWell(
          key: ValueKey('leg-${leg.from.id}-${leg.to.id}'),
          borderRadius: BorderRadius.circular(5),
          onTap: () => Navigator.pushNamed<void>(
            context,
            cheapest == null
                ? AppRoute.addTransportOption
                : AppRoute.transportOptions,
            arguments: args,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(
                  cheapest == null
                      ? Icons.add_circle_outline
                      : TripFormat.modeIcon(cheapest.mode),
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: cheapest == null ? FontWeight.w600 : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
