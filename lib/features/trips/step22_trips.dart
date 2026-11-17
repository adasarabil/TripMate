import 'package:flutter/widgets.dart';

import '../../app/step22_routes.dart';
import '../../ui/app_widgets.dart';

Widget createTripScreen() => const PendingStep22Screen('New Trip');

Widget tripRouteTab(String tripId) =>
    const PendingStep22Screen('Route', embedded: true);

Widget editCityStopScreen(CityEditArgs args) => PendingStep22Screen(
  args.stopId == null ? 'Add City Stop' : 'Edit City Stop',
);

Widget transportOptionsScreen(LegArgs args) =>
    const PendingStep22Screen('Transport Options');

Widget addTransportOptionScreen(LegArgs args) =>
    const PendingStep22Screen('Add Transport Option');
