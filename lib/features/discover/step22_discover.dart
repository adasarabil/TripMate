import 'package:flutter/widgets.dart';

import '../../app/step22_routes.dart';
import '../../ui/app_widgets.dart';

Widget itineraryScreen(CityStopArgs args) =>
    const PendingStep22Screen('Daily Itinerary');

Widget addActivityScreen(ActivityArgs args) =>
    const PendingStep22Screen('Add Activity');

Widget placesTripTab(String tripId) =>
    const PendingStep22Screen('Places', embedded: true);

Widget addPlaceLogScreen(PlaceFormArgs args) =>
    const PendingStep22Screen('Add Place Log');

Widget nearbyScreen(CityStopArgs args) =>
    const PendingStep22Screen('Nearby Recommendations');
