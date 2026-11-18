import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../app/step22_routes.dart';
import '../../data/demo_models.dart';
import '../../data/trip_store.dart';
import '../../ui/app_theme.dart';
import 'trip_format.dart';

/// 10 · Transport Options for one directed leg of the route.
class TransportOptionsScreen extends StatefulWidget {
  const TransportOptionsScreen({super.key, required this.args});

  final LegArgs args;

  @override
  State<TransportOptionsScreen> createState() => _TransportOptionsScreenState();
}

class _TransportOptionsScreenState extends State<TransportOptionsScreen> {
  /// Null means the "All" filter.
  TransportMode? _filter;
  var _adding = false;

  LegArgs get _args => widget.args;

  Future<void> _addOption() async {
    if (_adding) return;
    _adding = true;
    final store = context.read<TripStore>();
    final before = store
        .optionsForLeg(_args.tripId, _args.fromStopId, _args.toStopId)
        .map((option) => option.id)
        .toSet();
    try {
      await Navigator.pushNamed<void>(
        context,
        AppRoute.addTransportOption,
        arguments: _args,
      );
    } finally {
      _adding = false;
    }
    if (!mounted) return;
    final added = store
        .optionsForLeg(_args.tripId, _args.fromStopId, _args.toStopId)
        .where((option) => !before.contains(option.id));
    // Make sure the new option is visible under the current filter.
    final filter = _filter;
    if (filter != null && added.any((option) => option.mode != filter)) {
      setState(() => _filter = null);
    }
  }

  Future<void> _remove(TransportOption option, Trip trip) async {
    final store = context.read<TripStore>();
    if (await confirmTripAction(
      context,
      title: 'Remove option?',
      message:
          'Remove ${option.mode.label.toLowerCase()} by ${option.company} '
          '(${TripFormat.money(option.priceMinor, trip.currencyCode)})?',
      confirmLabel: 'Remove',
    )) {
      store.removeTransportOption(option.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<TripStore>();
    final trip = store.byId(_args.tripId);
    final leg = trip == null
        ? null
        : store.legFor(_args.tripId, _args.fromStopId, _args.toStopId);
    if (trip == null || leg == null) {
      return const UnavailableScreen(
        message: 'This leg is no longer part of the route.',
      );
    }

    final theme = Theme.of(context);
    final legCount = store.legsOf(trip.id).length;
    final options = store.optionsForLeg(trip.id, leg.from.id, leg.to.id);
    final cheapestId = leg.cheapest?.id;
    final filter = _filter;
    final visible = filter == null
        ? options
        : options.where((option) => option.mode == filter).toList();
    final summary = store.routeSummary(trip.id);
    final meta = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${leg.from.name} → ${leg.to.name}',
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.lg,
            AppSpacing.page,
            96,
          ),
          children: [
            Text(
              'Leg ${leg.index + 1} of $legCount · '
              '${TripFormat.shortDate(leg.from.departure)}',
              style: meta,
            ),
            const SizedBox(height: AppSpacing.md),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<TransportMode?>(
                showSelectedIcon: false,
                segments: [
                  const ButtonSegment(value: null, label: Text('All')),
                  for (final mode in TransportMode.values)
                    ButtonSegment(value: mode, label: Text(mode.label)),
                ],
                selected: {filter},
                onSelectionChanged: (selection) =>
                    setState(() => _filter = selection.first),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (options.isEmpty)
              const _EmptyOptions(
                message: 'No transport options yet. Add one with +.',
              )
            else if (visible.isEmpty)
              _EmptyOptions(
                message:
                    'No ${filter!.label.toLowerCase()} options for '
                    'this leg.',
              )
            else
              for (final option in visible)
                _OptionCard(
                  key: ValueKey(option.id),
                  option: option,
                  currencyCode: trip.currencyCode,
                  isCheapest: option.id == cheapestId,
                  onRemove: () => _remove(option, trip),
                ),
            const SizedBox(height: AppSpacing.sm),
            Card(
              color: theme.colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    const Expanded(child: Text('Cheapest route total')),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      summary.isComplete
                          ? TripFormat.money(
                              summary.totalMinor,
                              trip.currencyCode,
                            )
                          : '${TripFormat.money(summary.totalMinor, trip.currencyCode)}'
                                ' · incomplete',
                      key: const Key('transport-route-total'),
                      textAlign: TextAlign.end,
                      style: theme.textTheme.titleSmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add transport option',
        onPressed: _addOption,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    super.key,
    required this.option,
    required this.currencyCode,
    required this.isCheapest,
    required this.onRemove,
  });

  final TransportOption option;
  final String currencyCode;
  final bool isCheapest;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meta = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Card(
        shape: isCheapest
            ? RoundedRectangleBorder(
                side: BorderSide(color: theme.colorScheme.primary, width: 2),
                borderRadius: BorderRadius.circular(7),
              )
            : null,
        child: Padding(
          padding: const EdgeInsets.only(left: AppSpacing.md),
          child: Row(
            children: [
              Icon(TripFormat.modeIcon(option.mode), size: 22),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isCheapest)
                        Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            'CHEAPEST',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      Text(
                        '${option.mode.label} · ${option.company}',
                        style: theme.textTheme.titleSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${TripFormat.duration(option.durationMinutes)} · '
                        'Departs ${TripFormat.time(option.departure)}',
                        style: meta,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                TripFormat.money(option.priceMinor, currencyCode),
                style: theme.textTheme.titleSmall,
              ),
              IconButton(
                tooltip: 'Remove ${option.company}',
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

class _EmptyOptions extends StatelessWidget {
  const _EmptyOptions({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}
