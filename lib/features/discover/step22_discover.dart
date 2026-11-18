import 'package:flutter/widgets.dart';

import '../../app/step22_routes.dart';
import '../../ui/app_widgets.dart';
import 'add_activity_screen.dart';
import 'itinerary_screen.dart';
import 'places_tab.dart';

Widget itineraryScreen(CityStopArgs args) => ItineraryScreen(args: args);

Widget addActivityScreen(ActivityArgs args) => AddActivityScreen(args: args);

Widget placesTripTab(String tripId) => PlacesTab(tripId: tripId);

Widget addPlaceLogScreen(PlaceFormArgs args) =>
    const PendingStep22Screen('Add Place Log');

Widget nearbyScreen(CityStopArgs args) =>
    const PendingStep22Screen('Nearby Recommendations');
