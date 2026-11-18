import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../app/step22_routes.dart';
import '../../data/demo_models.dart';
import '../../data/places_store.dart';
import '../../data/trip_store.dart';
import '../../ui/app_theme.dart';
import 'discover_common.dart';

class NearbyScreen extends StatefulWidget {
  const NearbyScreen({super.key, required this.args});

  final CityStopArgs args;

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> {
  PlaceType? _type;

  @override
  Widget build(BuildContext context) {
    final args = widget.args;
    final trip = context.select((TripStore store) => store.byId(args.tripId));
    final stop = findStop(trip, args.stopId);
    if (stop == null) {
      return const UnavailableScreen(
        message: 'This city stop is no longer part of the trip.',
      );
    }
    final store = context.watch<PlacesStore>();
    final places = store.nearbyFor(args.tripId, stop.id, type: _type);
    final theme = Theme.of(context);
    final meta = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final hasHotel = stop.hotelName.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text('Nearby · ${stop.name}', overflow: TextOverflow.ellipsis),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.lg,
            AppSpacing.page,
            AppSpacing.xl,
          ),
          children: [
            if (!hasHotel)
              DiscoverEmptyState(
                message:
                    'Add a hotel to ${stop.name} to see places around it.',
                actionLabel: 'Edit city stop',
                onAction: () => Navigator.pushNamed<void>(
                  context,
                  AppRoute.editCityStop,
                  arguments: CityEditArgs(args.tripId, stop.id),
                ),
              )
            else ...[
              Card(
                child: ListTile(
                  leading: const Icon(Icons.hotel_outlined),
                  title: Text(stop.hotelName),
                  subtitle: stop.hotelAddress.isEmpty
                      ? null
                      : Text(stop.hotelAddress),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              PlaceTypeFilter(
                selected: _type,
                onChanged: (type) => setState(() => _type = type),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Sorted by distance from your hotel. Demo distances; live '
                'location arrives with Google Places.',
                style: meta,
              ),
              const SizedBox(height: AppSpacing.md),
              if (places.isEmpty)
                DiscoverEmptyState(
                  message: _type == null
                      ? 'No recommendations for ${stop.name} yet.'
                      : 'No ${_type!.label.toLowerCase()} places nearby.',
                )
              else
                for (final place in places)
                  _NearbyCard(
                    key: ValueKey(place.id),
                    place: place,
                    log: store.logForPlace(args.tripId, place.id),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NearbyCard extends StatelessWidget {
  const _NearbyCard({super.key, required this.place, required this.log});

  final NearbyPlace place;
  final PlaceLog? log;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meta = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final logged = log;
    final author = logged == null
        ? null
        : demoUsers[logged.authorId]?.displayName.split(' ').first;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                place.type == PlaceType.food
                    ? Icons.restaurant_outlined
                    : Icons.local_activity_outlined,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(place.name, style: theme.textTheme.titleSmall),
                    Text(
                      '${place.type.label} · ${place.description}',
                      style: meta,
                    ),
                    if (logged != null)
                      Text(
                        '${'★' * logged.rating} logged'
                        '${author == null ? '' : ' by $author'}',
                        style: meta,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                DiscoverFormat.distance(place.distanceMeters),
                style: theme.textTheme.labelLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
