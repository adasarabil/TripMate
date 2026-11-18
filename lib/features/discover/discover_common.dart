import 'package:material_ui/material_ui.dart';

import '../../data/demo_models.dart';
import '../../data/places_store.dart';
import '../../ui/app_theme.dart';
import '../../ui/app_widgets.dart';

abstract final class DiscoverFormat {
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

  static String shortDate(DateTime date) =>
      '${date.day} ${_months[date.month - 1]}';

  static String dateRange(DateTime start, DateTime end) {
    if (start.year == end.year && start.month == end.month) {
      if (start.day == end.day) return shortDate(start);
      return '${start.day}–${shortDate(end)}';
    }
    return '${shortDate(start)}–${shortDate(end)}';
  }

  static String time(DateTime time) =>
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';

  static String distance(int meters) {
    if (meters < 1000) return '$meters m';
    final km = meters / 1000;
    return '${km.toStringAsFixed(km < 10 ? 1 : 0)} km';
  }
}

List<DateTime> stopDays(CityStop stop) {
  final first = DateUtils.dateOnly(stop.arrival);
  final last = DateUtils.dateOnly(stop.departure);
  final days = <DateTime>[];
  for (
    var day = first;
    !day.isAfter(last);
    day = DateUtils.addDaysToDate(day, 1)
  ) {
    days.add(day);
  }
  return days;
}

CityStop? findStop(Trip? trip, String? stopId) {
  if (trip == null || stopId == null) return null;
  for (final stop in trip.stops) {
    if (stop.id == stopId) return stop;
  }
  return null;
}

class PlaceTypeFilter extends StatelessWidget {
  const PlaceTypeFilter({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final PlaceType? selected;
  final ValueChanged<PlaceType?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SegmentedButton<PlaceType?>(
        showSelectedIcon: false,
        segments: [
          const ButtonSegment(value: null, label: Text('All')),
          for (final type in PlaceType.values)
            ButtonSegment(value: type, label: Text(type.label)),
        ],
        selected: {selected},
        onSelectionChanged: (selection) => onChanged(selection.first),
      ),
    );
  }
}

class PlaceThumb extends StatelessWidget {
  const PlaceThumb({super.key, this.imageUrl, this.size = 56});

  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    final fallback = Image.asset(AppAssets.imageFallback, fit: BoxFit.cover);
    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: SizedBox.square(
        dimension: size,
        child: AspectRatio(
          aspectRatio: 1,
          child: url == null
              ? fallback
              : Image.network(
                  url,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) => progress == null
                      ? child
                      : ColoredBox(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          child: const Center(
                            child: SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                  errorBuilder: (context, error, stackTrace) => fallback,
                ),
        ),
      ),
    );
  }
}

class DiscoverEmptyState extends StatelessWidget {
  const DiscoverEmptyState({
    super.key,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = actionLabel;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (label != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(onPressed: onAction, child: Text(label)),
          ],
        ],
      ),
    );
  }
}

Future<bool> confirmRemoval(BuildContext context, String name) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Remove?'),
      content: Text('Remove “$name”?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Remove'),
        ),
      ],
    ),
  );
  return confirmed == true && context.mounted;
}
