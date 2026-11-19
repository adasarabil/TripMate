import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../data/group_store.dart';
import '../data/places_store.dart';
import '../data/trip_store.dart';
import '../features/discover/step22_discover.dart' as discover;
import '../features/expenses/step22_expenses.dart' as expenses;
import '../features/groups/step22_groups.dart' as groups;
import '../features/trips/step22_trips.dart' as trips;
import '../ui/app_theme.dart';
import 'auth_screen.dart';
import 'demo_session.dart';
import 'main_shell.dart';
import 'trip_detail_shell.dart';
import 'welcome_screen.dart';

abstract final class AppRoute {
  static const welcome = '/';
  static const logIn = '/login';
  static const signUp = '/signup';
  static const home = '/home';

  static const createTrip = '/trips/new';
  static const tripDetail = '/trips/detail';
  static const editCityStop = '/trips/city/edit';
  static const itinerary = '/trips/city/itinerary';
  static const addActivity = '/trips/city/activity/new';
  static const transportOptions = '/trips/transport';
  static const addTransportOption = '/trips/transport/new';
  static const addExpense = '/trips/expense/new';
  static const settleUp = '/trips/settle';
  static const addPlaceLog = '/trips/places/new';
  static const nearby = '/trips/nearby';

  static const groupDetail = '/groups/detail';
  static const joinGroup = '/groups/join';
  static const settings = '/settings';

  static Route<dynamic> generate(RouteSettings route) {
    Widget build(BuildContext context) => _screenFor(context, route);

    // These feature routes may return the ID of the new or joined record.
    if (route.name == createTrip || route.name == joinGroup) {
      return MaterialPageRoute<String>(settings: route, builder: build);
    }
    return MaterialPageRoute<void>(settings: route, builder: build);
  }

  static void openHome(BuildContext context) {
    context.read<DemoSession>().selectTab(AppMainTab.trips);
    Navigator.pushNamedAndRemoveUntil<void>(context, home, (_) => false);
  }

  static void logOut(BuildContext context) {
    context.read<DemoSession>().selectTab(AppMainTab.trips);
    Navigator.pushNamedAndRemoveUntil<void>(context, welcome, (_) => false);
  }

  static Widget _screenFor(BuildContext context, RouteSettings route) {
    bool hasTrip(String id) => context.read<TripStore>().byId(id) != null;

    return switch ((route.name, route.arguments)) {
      (welcome, null) => const WelcomeScreen(),
      (logIn, null) => const AuthScreen.logIn(),
      (signUp, null) => const AuthScreen.signUp(),
      (home, null) => const MainShell(),
      (createTrip, null) => trips.createTripScreen(),
      (tripDetail, String id) => TripDetailShell(tripId: id),
      (editCityStop, CityEditArgs args) when hasTrip(args.tripId) =>
        trips.editCityStopScreen(args),
      (itinerary, CityStopArgs args) when hasTrip(args.tripId) =>
        discover.itineraryScreen(args),
      (addActivity, ActivityArgs args) when hasTrip(args.tripId) =>
        discover.addActivityScreen(args),
      (transportOptions, LegArgs args) when hasTrip(args.tripId) =>
        trips.transportOptionsScreen(args),
      (addTransportOption, LegArgs args) when hasTrip(args.tripId) =>
        trips.addTransportOptionScreen(args),
      (addExpense, String id) when hasTrip(id) => expenses.addExpenseScreen(id),
      (settleUp, String id) when hasTrip(id) => expenses.settleUpScreen(id),
      (addPlaceLog, PlaceFormArgs args) when hasTrip(args.tripId) =>
        discover.addPlaceLogScreen(args),
      (nearby, CityStopArgs args) when hasTrip(args.tripId) =>
        discover.nearbyScreen(args),
      (groupDetail, String id)
          when context.read<GroupStore>().byId(id) != null =>
        groups.groupDetailScreen(id),
      (joinGroup, null) => groups.joinGroupScreen(),
      (settings, null) => groups.settingsScreen(),
      _ => const UnavailableScreen(),
    };
  }
}

class CityStopArgs {
  const CityStopArgs(this.tripId, this.stopId);

  final String tripId;
  final String stopId;
}

class CityEditArgs {
  const CityEditArgs(this.tripId, [this.stopId]);

  final String tripId;
  final String? stopId;
}

class ActivityArgs {
  const ActivityArgs(this.tripId, this.stopId, this.day);

  final String tripId;
  final String stopId;
  final DateTime day;
}

class LegArgs {
  const LegArgs(this.tripId, this.fromStopId, this.toStopId);

  final String tripId;
  final String fromStopId;
  final String toStopId;
}

class PlaceFormArgs {
  const PlaceFormArgs(this.tripId, [this.stopId, this.place]);

  final String tripId;
  final String? stopId;
  final NearbyPlace? place;
}

class UnavailableScreen extends StatelessWidget {
  const UnavailableScreen({
    super.key,
    this.message = 'This page could not be opened.',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page unavailable')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.page),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(
                onPressed: () {
                  final navigator = Navigator.of(context);
                  if (navigator.canPop()) {
                    navigator.pop();
                  } else {
                    AppRoute.openHome(context);
                  }
                },
                child: const Text('Go back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
