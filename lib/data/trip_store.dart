import 'package:flutter/foundation.dart';

import 'demo_fixtures.dart';
import 'demo_models.dart';

enum TransportMode {
  bus('Bus'),
  train('Train'),
  flight('Flight');

  const TransportMode(this.label);

  final String label;
}

/// One saved way to travel a directed leg between two stops of a trip.
class TransportOption {
  const TransportOption({
    required this.id,
    required this.tripId,
    required this.fromStopId,
    required this.toStopId,
    required this.mode,
    required this.company,
    required this.priceMinor,
    required this.durationMinutes,
    required this.departure,
  });

  final String id;
  final String tripId;
  final String fromStopId;
  final String toStopId;
  final TransportMode mode;
  final String company;

  /// Price in minor units (cents, kuruş) of the trip currency.
  final int priceMinor;
  final int durationMinutes;
  final DateTime departure;

  bool isFor(String tripId, String fromStopId, String toStopId) =>
      this.tripId == tripId &&
      this.fromStopId == fromStopId &&
      this.toStopId == toStopId;
}

/// A pair of neighbouring stops in the current route order.
class RouteLeg {
  const RouteLeg({
    required this.index,
    required this.from,
    required this.to,
    required this.cheapest,
  });

  /// Zero-based position of the leg in the route.
  final int index;
  final CityStop from;
  final CityStop to;
  final TransportOption? cheapest;
}

class RouteCostSummary {
  const RouteCostSummary({
    required this.totalMinor,
    required this.legCount,
    required this.missingLegCount,
  });

  /// Sum of the cheapest option of every leg that has at least one option.
  final int totalMinor;
  final int legCount;
  final int missingLegCount;

  bool get isComplete => missingLegCount == 0;
}

class TripStore extends ChangeNotifier {
  final List<Trip> _trips = List.of(DemoFixtures.trips);
  final List<TransportOption> _options = List.of(_seedOptions);
  var _idCounter = 0;

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
    if (_trips.length != lengthBefore) {
      _options.removeWhere((option) => option.tripId == id);
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------- Trips

  /// Adds a new trip without stops and returns its unique ID.
  String addTrip({
    required String title,
    required String groupId,
    required DateTime start,
    required DateTime end,
    required String currencyCode,
    String? coverAsset,
  }) {
    final id = _newId('trip', (id) => byId(id) != null);
    _trips.add(
      Trip(
        id: id,
        title: title.trim(),
        groupId: groupId,
        start: _dateOnly(start),
        end: _dateOnly(end),
        currencyCode: currencyCode,
        stops: const [],
        coverAsset: coverAsset,
      ),
    );
    notifyListeners();
    return id;
  }

  // ---------------------------------------------------------------- Stops

  CityStop? stopById(String tripId, String stopId) {
    final trip = byId(tripId);
    if (trip == null) return null;
    for (final stop in trip.stops) {
      if (stop.id == stopId) return stop;
    }
    return null;
  }

  /// Updates the stop with [stopId], or appends a new stop when [stopId] is
  /// null. Returns the saved stop ID, or null if the trip or stop is gone.
  String? saveStop(
    String tripId, {
    String? stopId,
    required String name,
    required DateTime arrival,
    required DateTime departure,
    required String hotelName,
    required String hotelAddress,
  }) {
    final tripIndex = _tripIndex(tripId);
    if (tripIndex < 0) return null;
    final trip = _trips[tripIndex];
    final stops = List.of(trip.stops);

    final id =
        stopId ??
        _newId(
          'stop',
          (id) => _trips.any((t) => t.stops.any((s) => s.id == id)),
        );
    final stop = CityStop(
      id: id,
      name: name.trim(),
      arrival: _dateOnly(arrival),
      departure: _dateOnly(departure),
      hotelName: hotelName.trim(),
      hotelAddress: hotelAddress.trim(),
    );
    if (stopId == null) {
      stops.add(stop);
    } else {
      final index = stops.indexWhere((s) => s.id == stopId);
      if (index < 0) return null;
      stops[index] = stop;
    }
    _trips[tripIndex] = _withStops(trip, stops);
    notifyListeners();
    return id;
  }

  /// Removes a stop and every transport option that starts or ends there.
  bool removeStop(String tripId, String stopId) {
    final tripIndex = _tripIndex(tripId);
    if (tripIndex < 0) return false;
    final trip = _trips[tripIndex];
    final stops = List.of(trip.stops);
    final lengthBefore = stops.length;
    stops.removeWhere((stop) => stop.id == stopId);
    if (stops.length == lengthBefore) return false;

    _trips[tripIndex] = _withStops(trip, stops);
    _options.removeWhere(
      (option) =>
          option.tripId == tripId &&
          (option.fromStopId == stopId || option.toStopId == stopId),
    );
    notifyListeners();
    return true;
  }

  /// Moves the stop at [from] so it ends up at index [to] of the new order.
  /// Stop dates are kept as they are; the user edits them explicitly.
  void moveStop(String tripId, int from, int to) {
    final tripIndex = _tripIndex(tripId);
    if (tripIndex < 0) return;
    final trip = _trips[tripIndex];
    final stops = List.of(trip.stops);
    if (from < 0 || from >= stops.length || to < 0 || to >= stops.length) {
      return;
    }
    if (from == to) return;
    stops.insert(to, stops.removeAt(from));
    _trips[tripIndex] = _withStops(trip, stops);
    notifyListeners();
  }

  // ------------------------------------------------------------ Transport

  /// Options of one directed leg in the order they were added.
  List<TransportOption> optionsForLeg(
    String tripId,
    String fromStopId,
    String toStopId,
  ) => List.unmodifiable(
    _options.where((option) => option.isFor(tripId, fromStopId, toStopId)),
  );

  /// The lowest-priced option of the leg. Ties keep the earlier option.
  TransportOption? cheapestForLeg(
    String tripId,
    String fromStopId,
    String toStopId,
  ) {
    TransportOption? cheapest;
    for (final option in _options) {
      if (!option.isFor(tripId, fromStopId, toStopId)) continue;
      if (cheapest == null || option.priceMinor < cheapest.priceMinor) {
        cheapest = option;
      }
    }
    return cheapest;
  }

  /// Neighbouring stop pairs of the current route order.
  List<RouteLeg> legsOf(String tripId) {
    final trip = byId(tripId);
    if (trip == null) return const [];
    return [
      for (var i = 0; i + 1 < trip.stops.length; i++)
        RouteLeg(
          index: i,
          from: trip.stops[i],
          to: trip.stops[i + 1],
          cheapest: cheapestForLeg(
            tripId,
            trip.stops[i].id,
            trip.stops[i + 1].id,
          ),
        ),
    ];
  }

  /// The leg from [fromStopId] to [toStopId], or null if they are no longer
  /// neighbours in that direction.
  RouteLeg? legFor(String tripId, String fromStopId, String toStopId) {
    for (final leg in legsOf(tripId)) {
      if (leg.from.id == fromStopId && leg.to.id == toStopId) return leg;
    }
    return null;
  }

  RouteCostSummary routeSummary(String tripId) {
    final legs = legsOf(tripId);
    var total = 0;
    var missing = 0;
    for (final leg in legs) {
      final cheapest = leg.cheapest;
      if (cheapest == null) {
        missing++;
      } else {
        total += cheapest.priceMinor;
      }
    }
    return RouteCostSummary(
      totalMinor: total,
      legCount: legs.length,
      missingLegCount: missing,
    );
  }

  /// Saves a new option for an existing leg and returns its ID, or null when
  /// the stops are no longer neighbours.
  String? addTransportOption({
    required String tripId,
    required String fromStopId,
    required String toStopId,
    required TransportMode mode,
    required String company,
    required int priceMinor,
    required int durationMinutes,
    required DateTime departure,
  }) {
    if (legFor(tripId, fromStopId, toStopId) == null) return null;
    if (priceMinor <= 0 || durationMinutes <= 0) return null;
    final id = _newId('option', (id) => _options.any((o) => o.id == id));
    _options.add(
      TransportOption(
        id: id,
        tripId: tripId,
        fromStopId: fromStopId,
        toStopId: toStopId,
        mode: mode,
        company: company.trim(),
        priceMinor: priceMinor,
        durationMinutes: durationMinutes,
        departure: departure,
      ),
    );
    notifyListeners();
    return id;
  }

  bool removeTransportOption(String optionId) {
    final lengthBefore = _options.length;
    _options.removeWhere((option) => option.id == optionId);
    if (_options.length == lengthBefore) return false;
    notifyListeners();
    return true;
  }

  // -------------------------------------------------------------- Helpers

  int _tripIndex(String tripId) => _trips.indexWhere((t) => t.id == tripId);

  String _newId(String prefix, bool Function(String id) isTaken) {
    String id;
    do {
      id = '$prefix-${++_idCounter}';
    } while (isTaken(id));
    return id;
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static Trip _withStops(Trip trip, List<CityStop> stops) => Trip(
    id: trip.id,
    title: trip.title,
    groupId: trip.groupId,
    start: trip.start,
    end: trip.end,
    currencyCode: trip.currencyCode,
    stops: List.unmodifiable(stops),
    coverAsset: trip.coverAsset,
    imageUrl: trip.imageUrl,
  );

  static final _seedOptions = <TransportOption>[
    TransportOption(
      id: 'rome-florence-bus',
      tripId: 'interrail-summer',
      fromStopId: 'rome',
      toStopId: 'florence',
      mode: TransportMode.bus,
      company: 'FlixBus',
      priceMinor: 1900,
      durationMinutes: 195,
      departure: DateTime(2026, 7, 14, 8, 30),
    ),
    TransportOption(
      id: 'rome-florence-train',
      tripId: 'interrail-summer',
      fromStopId: 'rome',
      toStopId: 'florence',
      mode: TransportMode.train,
      company: 'Italo',
      priceMinor: 2900,
      durationMinutes: 95,
      departure: DateTime(2026, 7, 14, 9, 10),
    ),
    TransportOption(
      id: 'rome-florence-flight',
      tripId: 'interrail-summer',
      fromStopId: 'rome',
      toStopId: 'florence',
      mode: TransportMode.flight,
      company: 'ITA Airways',
      priceMinor: 7400,
      durationMinutes: 65,
      departure: DateTime(2026, 7, 14, 11, 45),
    ),
    TransportOption(
      id: 'florence-venice-train',
      tripId: 'interrail-summer',
      fromStopId: 'florence',
      toStopId: 'venice',
      mode: TransportMode.train,
      company: 'Trenitalia Regionale',
      priceMinor: 1200,
      durationMinutes: 125,
      departure: DateTime(2026, 7, 16, 10, 5),
    ),
    TransportOption(
      id: 'florence-venice-bus',
      tripId: 'interrail-summer',
      fromStopId: 'florence',
      toStopId: 'venice',
      mode: TransportMode.bus,
      company: 'FlixBus',
      priceMinor: 1500,
      durationMinutes: 180,
      departure: DateTime(2026, 7, 16, 9, 0),
    ),
    TransportOption(
      id: 'izmir-cesme-bus',
      tripId: 'weekend-in-izmir',
      fromStopId: 'izmir',
      toStopId: 'cesme',
      mode: TransportMode.bus,
      company: 'Çeşme Seyahat',
      priceMinor: 25000,
      durationMinutes: 75,
      departure: DateTime(2026, 10, 4, 10, 0),
    ),
    TransportOption(
      id: 'sarajevo-mostar-train',
      tripId: 'balkan-tour',
      fromStopId: 'sarajevo',
      toStopId: 'mostar',
      mode: TransportMode.train,
      company: 'ŽFBH',
      priceMinor: 800,
      durationMinutes: 125,
      departure: DateTime(2026, 4, 12, 7, 15),
    ),
  ];
}
