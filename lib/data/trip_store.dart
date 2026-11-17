import 'package:flutter/foundation.dart';

import 'demo_fixtures.dart';
import 'demo_models.dart';

class TripStore extends ChangeNotifier {
  final List<Trip> _trips = List.of(DemoFixtures.trips);

  List<Trip> get trips => List.unmodifiable(_trips);
  DateTime get demoToday => DemoFixtures.today;

  Trip? byId(String id) {
    for (final trip in _trips) {
      if (trip.id == id) return trip;
    }
    return null;
  }

  void removeTrip(String id) {
    final lengthBefore = _trips.length;
    _trips.removeWhere((trip) => trip.id == id);
    if (_trips.length != lengthBefore) notifyListeners();
  }
}
