import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../data/trip_store.dart';
import '../features/discover/step22_discover.dart' as discover;
import '../features/expenses/step22_expenses.dart' as expenses;
import '../features/trips/step22_trips.dart' as trips;
import '../ui/app_theme.dart';
import 'step22_routes.dart';
import 'trip_actions.dart';

class TripDetailShell extends StatelessWidget {
  const TripDetailShell({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context) {
    final trip = context.select((TripStore store) => store.byId(tripId));
    if (trip == null) {
      return const UnavailableScreen(message: 'This trip could not be found.');
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(trip.title, overflow: TextOverflow.ellipsis),
          actions: [
            PopupMenuButton<void>(
              tooltip: 'Trip options',
              itemBuilder: (context) => [
                PopupMenuItem<void>(
                  onTap: () async {
                    if (await confirmTripRemoval(context, trip) &&
                        context.mounted) {
                      AppRoute.openHome(context);
                    }
                  },
                  child: const Text('Remove trip'),
                ),
              ],
            ),
          ],
          bottom: const TabBar(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.page),
            tabs: [
              Tab(text: 'Route'),
              Tab(text: 'Expenses'),
              Tab(text: 'Places'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            trips.tripRouteTab(tripId),
            expenses.expensesTripTab(tripId),
            discover.placesTripTab(tripId),
          ],
        ),
      ),
    );
  }
}
