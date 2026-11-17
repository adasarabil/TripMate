import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../data/demo_models.dart';
import '../data/trip_store.dart';

Future<bool> confirmTripRemoval(BuildContext context, Trip trip) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Remove trip?'),
      content: Text('Remove “${trip.title}” from My Trips?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Confirm'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return false;

  context.read<TripStore>().removeTrip(trip.id);
  return true;
}
