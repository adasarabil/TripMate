import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../app/step22_routes.dart';
import '../../data/demo_models.dart';
import '../../data/places_store.dart';
import '../../data/trip_store.dart';
import '../../ui/app_theme.dart';
import 'discover_common.dart';

class PlacesTab extends StatefulWidget {
  const PlacesTab({super.key, required this.tripId});

  final String tripId;

  @override
  State<PlacesTab> createState() => _PlacesTabState();
}

class _PlacesTabState extends State<PlacesTab> {
  String? _stopId;
  PlaceType? _type;

  Future<void> _addLog(String? stopId) async {
    final result = await Navigator.pushNamed<Object?>(
      context,
      AppRoute.addPlaceLog,
      arguments: PlaceFormArgs(widget.tripId, stopId),
    );
    if (!mounted || result is! String) return;
    setState(() {
      _stopId = result;
      _type = null;
    });
  }

  Future<void> _removeLog(PlaceLog log) async {
    if (await confirmRemoval(context, log.name) && mounted) {
      context.read<PlacesStore>().removeLog(log.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = context.select((TripStore store) => store.byId(widget.tripId));
    if (trip == null) return const SizedBox.shrink();
    if (trip.stops.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.page),
        children: [
          DiscoverEmptyState(
            message: 'Add a city to your route to start logging places.',
            actionLabel: 'Add city',
            onAction: () => Navigator.pushNamed<void>(
              context,
              AppRoute.editCityStop,
              arguments: CityEditArgs(widget.tripId),
            ),
          ),
        ],
      );
    }

    final stop = findStop(trip, _stopId) ?? trip.stops.first;
    final logs = context.watch<PlacesStore>().logsFor(
      trip.id,
      stop.id,
      type: _type,
    );

    return Scaffold(
      body: ListView(
        key: PageStorageKey('places-${trip.id}'),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.lg,
          AppSpacing.page,
          96,
        ),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<String>(
              showSelectedIcon: false,
              segments: [
                for (final s in trip.stops)
                  ButtonSegment(value: s.id, label: Text(s.name)),
              ],
              selected: {stop.id},
              onSelectionChanged: (selection) =>
                  setState(() => _stopId = selection.first),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          PlaceTypeFilter(
            selected: _type,
            onChanged: (type) => setState(() => _type = type),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed<void>(
              context,
              AppRoute.nearby,
              arguments: CityStopArgs(trip.id, stop.id),
            ),
            icon: const Icon(Icons.near_me_outlined),
            label: const Text('Nearby my hotel'),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (logs.isEmpty)
            DiscoverEmptyState(
              message: _type == null
                  ? 'No places logged in ${stop.name} yet. Add one with +.'
                  : 'No ${_type!.label.toLowerCase()} places in '
                        '${stop.name}.',
            )
          else
            for (final log in logs)
              _PlaceLogCard(
                key: ValueKey(log.id),
                log: log,
                onRemove: () => _removeLog(log),
              ),
        ],
      ),
      floatingActionButton: SizedBox.square(
        dimension: 48,
        child: FloatingActionButton(
          heroTag: 'places-fab',
          tooltip: 'Add place log',
          onPressed: () => _addLog(stop.id),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class _PlaceLogCard extends StatelessWidget {
  const _PlaceLogCard({super.key, required this.log, required this.onRemove});

  final PlaceLog log;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meta = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final author = demoUsers[log.authorId]?.displayName.split(' ').first;
    final note = log.note;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.only(left: 10, top: 10, bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PlaceThumb(imageUrl: log.imageUrl),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.name,
                      style: theme.textTheme.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Semantics(
                      label: '${log.type.label}, ${log.rating} of 5 stars',
                      excludeSemantics: true,
                      child: Text(
                        '${log.type.label} · '
                        '${'★' * log.rating}${'☆' * (5 - log.rating)}',
                        style: meta,
                      ),
                    ),
                    if (author != null) Text('by $author', style: meta),
                    if (note != null)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Text(note, style: theme.textTheme.bodySmall),
                      ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Remove ${log.name}',
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
