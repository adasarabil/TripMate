import 'package:flutter/widgets.dart';

import '../../app/step22_routes.dart';
import 'add_transport_option_screen.dart';
import 'city_stop_form_screen.dart';
import 'create_trip_screen.dart';
import 'route_tab.dart';
import 'transport_options_screen.dart';

Widget createTripScreen() => const CreateTripScreen();

Widget tripRouteTab(String tripId) => RouteTab(tripId: tripId);

Widget editCityStopScreen(CityEditArgs args) => CityStopFormScreen(args: args);

Widget transportOptionsScreen(LegArgs args) =>
    TransportOptionsScreen(args: args);

Widget addTransportOptionScreen(LegArgs args) =>
    AddTransportOptionScreen(args: args);
