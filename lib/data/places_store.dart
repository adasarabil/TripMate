import 'package:flutter/foundation.dart';

enum PlaceType {
  food('Food'),
  activity('Activity');

  const PlaceType(this.label);

  final String label;
}

class Activity {
  const Activity({
    required this.id,
    required this.tripId,
    required this.stopId,
    required this.start,
    required this.title,
    this.location,
    this.note,
  });

  final String id;
  final String tripId;
  final String stopId;

  final DateTime start;
  final String title;
  final String? location;
  final String? note;
}

class PlaceLog {
  const PlaceLog({
    required this.id,
    required this.tripId,
    required this.stopId,
    required this.name,
    required this.type,
    required this.rating,
    required this.authorId,
    this.placeId,
    this.note,
    this.location,
    this.imageUrl,
  });

  final String id;
  final String tripId;
  final String stopId;
  final String name;
  final PlaceType type;

  final int rating;
  final String authorId;

  final String? placeId;
  final String? note;
  final String? location;
  final String? imageUrl;
}

class NearbyPlace {
  const NearbyPlace({
    required this.id,
    required this.tripId,
    required this.stopId,
    required this.name,
    required this.type,
    required this.distanceMeters,
    required this.description,
  });

  final String id;
  final String tripId;
  final String stopId;
  final String name;
  final PlaceType type;

  final int distanceMeters;
  final String description;
}

class PlacesStore extends ChangeNotifier {
  final List<Activity> _activities = List.of(_seedActivities);
  final List<PlaceLog> _logs = List.of(_seedLogs);
  var _sequence = 0;

  List<Activity> activitiesFor(String tripId, String stopId, DateTime day) {
    return _activities
        .where(
          (a) =>
              a.tripId == tripId &&
              a.stopId == stopId &&
              a.start.year == day.year &&
              a.start.month == day.month &&
              a.start.day == day.day,
        )
        .toList()
      ..sort((a, b) {
        final byTime = a.start.compareTo(b.start);
        return byTime != 0 ? byTime : a.id.compareTo(b.id);
      });
  }

  String addActivity({
    required String tripId,
    required String stopId,
    required DateTime start,
    required String title,
    String? location,
    String? note,
  }) {
    final id = _newId('activity', (id) => _activities.any((a) => a.id == id));
    _activities.add(
      Activity(
        id: id,
        tripId: tripId,
        stopId: stopId,
        start: start,
        title: title.trim(),
        location: _optional(location),
        note: _optional(note),
      ),
    );
    notifyListeners();
    return id;
  }

  bool removeActivity(String id) {
    final lengthBefore = _activities.length;
    _activities.removeWhere((a) => a.id == id);
    if (_activities.length == lengthBefore) return false;
    notifyListeners();
    return true;
  }

  List<PlaceLog> logsFor(String tripId, String stopId, {PlaceType? type}) => [
    for (final log in _logs.reversed)
      if (log.tripId == tripId &&
          log.stopId == stopId &&
          (type == null || log.type == type))
        log,
  ];

  PlaceLog? logForPlace(String tripId, String placeId) {
    for (final log in _logs.reversed) {
      if (log.tripId == tripId && log.placeId == placeId) return log;
    }
    return null;
  }

  int logCountForTrips(Set<String> tripIds) =>
      _logs.where((log) => tripIds.contains(log.tripId)).length;

  String addLog({
    required String tripId,
    required String stopId,
    required String name,
    required PlaceType type,
    required int rating,
    required String authorId,
    String? placeId,
    String? note,
    String? location,
  }) {
    assert(rating >= 1 && rating <= 5);
    final id = _newId('log', (id) => _logs.any((log) => log.id == id));
    _logs.add(
      PlaceLog(
        id: id,
        tripId: tripId,
        stopId: stopId,
        name: name.trim(),
        type: type,
        rating: rating,
        authorId: authorId,
        placeId: placeId,
        note: _optional(note),
        location: _optional(location),
      ),
    );
    notifyListeners();
    return id;
  }

  bool removeLog(String id) {
    final lengthBefore = _logs.length;
    _logs.removeWhere((log) => log.id == id);
    if (_logs.length == lengthBefore) return false;
    notifyListeners();
    return true;
  }

  List<NearbyPlace> nearbyFor(
    String tripId,
    String stopId, {
    PlaceType? type,
  }) {
    final seen = <String>{};
    return _seedNearby
        .where(
          (place) =>
              place.tripId == tripId &&
              place.stopId == stopId &&
              (type == null || place.type == type) &&
              seen.add(place.id),
        )
        .toList()
      ..sort((a, b) {
        final byDistance = a.distanceMeters.compareTo(b.distanceMeters);
        return byDistance != 0 ? byDistance : a.id.compareTo(b.id);
      });
  }

  String _newId(String prefix, bool Function(String id) isTaken) {
    String id;
    do {
      id = '$prefix-${++_sequence}';
    } while (isTaken(id));
    return id;
  }

  static String? _optional(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  static const _trip = 'interrail-summer';

  static final _seedActivities = List<Activity>.unmodifiable([
    Activity(
      id: 'rome-colosseum-tour',
      tripId: _trip,
      stopId: 'rome',
      start: DateTime(2026, 7, 12, 9),
      title: 'Colosseum tour',
      location: 'Piazza del Colosseo',
    ),
    Activity(
      id: 'rome-trastevere-lunch',
      tripId: _trip,
      stopId: 'rome',
      start: DateTime(2026, 7, 12, 13),
      title: 'Lunch in Trastevere',
      location: 'Trastevere',
    ),
    Activity(
      id: 'rome-trevi-walk',
      tripId: _trip,
      stopId: 'rome',
      start: DateTime(2026, 7, 12, 18),
      title: 'Trevi Fountain walk',
      location: 'Piazza di Trevi',
    ),
    Activity(
      id: 'rome-vatican',
      tripId: _trip,
      stopId: 'rome',
      start: DateTime(2026, 7, 13, 10),
      title: 'Vatican Museums',
      location: 'Viale Vaticano',
    ),
    Activity(
      id: 'florence-duomo',
      tripId: _trip,
      stopId: 'florence',
      start: DateTime(2026, 7, 14, 15),
      title: 'Duomo climb',
      location: 'Piazza del Duomo',
    ),
    Activity(
      id: 'venice-gondola',
      tripId: _trip,
      stopId: 'venice',
      start: DateTime(2026, 7, 17, 11),
      title: 'Gondola ride',
      location: 'Grand Canal',
    ),
  ]);

  static const _unsplash = 'https://images.unsplash.com/photo-';
  static const _thumb = '?w=200&h=200&fit=crop';

  static const _seedLogs = <PlaceLog>[
    PlaceLog(
      id: 'log-rome-colosseum',
      tripId: _trip,
      stopId: 'rome',
      name: 'Colosseum',
      type: PlaceType.activity,
      rating: 4,
      authorId: 'ata',
      placeId: 'rome-colosseum',
      note: 'Book the morning slot to skip the queue.',
      imageUrl: '${_unsplash}1552832230-c0197dd311b5$_thumb',
    ),
    PlaceLog(
      id: 'log-rome-da-enzo',
      tripId: _trip,
      stopId: 'rome',
      name: 'Da Enzo al 29',
      type: PlaceType.food,
      rating: 5,
      authorId: 'naz',
      placeId: 'rome-da-enzo',
      note: 'Best cacio e pepe of the trip.',
      imageUrl: '${_unsplash}1621996346565-e3dbc646d9a9$_thumb',
    ),
    PlaceLog(
      id: 'log-rome-gelateria',
      tripId: _trip,
      stopId: 'rome',
      name: 'Gelateria del Teatro',
      type: PlaceType.food,
      rating: 5,
      authorId: 'emre',
      placeId: 'rome-gelateria',
      note: 'Try the lavender flavour.',
    ),
    PlaceLog(
      id: 'log-florence-duomo',
      tripId: _trip,
      stopId: 'florence',
      name: 'Duomo terrace',
      type: PlaceType.activity,
      rating: 5,
      authorId: 'arda',
      placeId: 'florence-duomo',
      note: '463 steps, worth every one.',
      imageUrl: '${_unsplash}1541370976299-4d24ebbc9077$_thumb',
    ),
    PlaceLog(
      id: 'log-florence-trattoria',
      tripId: _trip,
      stopId: 'florence',
      name: 'Trattoria Mario',
      type: PlaceType.food,
      rating: 4,
      authorId: 'ada',
      placeId: 'florence-trattoria',
      note: 'Lunch only, cash only.',
      imageUrl: '${_unsplash}1557499305-0af888c3d8ec$_thumb',
    ),
    PlaceLog(
      id: 'log-venice-grand-canal',
      tripId: _trip,
      stopId: 'venice',
      name: 'Grand Canal at sunset',
      type: PlaceType.activity,
      rating: 5,
      authorId: 'naz',
      placeId: 'venice-grand-canal',
      imageUrl: '${_unsplash}1514890547357-a9ee288728e0$_thumb',
    ),
  ];

  static const _seedNearby = <NearbyPlace>[
    NearbyPlace(
      id: 'rome-gelateria',
      tripId: _trip,
      stopId: 'rome',
      name: 'Gelateria del Teatro',
      type: PlaceType.food,
      distanceMeters: 350,
      description: 'Artisan gelato in a quiet alley.',
    ),
    NearbyPlace(
      id: 'rome-trevi',
      tripId: _trip,
      stopId: 'rome',
      name: 'Trevi Fountain',
      type: PlaceType.activity,
      distanceMeters: 900,
      description: 'Baroque fountain, best before 8 am.',
    ),
    NearbyPlace(
      id: 'rome-colosseum',
      tripId: _trip,
      stopId: 'rome',
      name: 'Colosseum',
      type: PlaceType.activity,
      distanceMeters: 1400,
      description: 'Ancient amphitheatre with guided tours.',
    ),
    NearbyPlace(
      id: 'rome-da-enzo',
      tripId: _trip,
      stopId: 'rome',
      name: 'Da Enzo al 29',
      type: PlaceType.food,
      distanceMeters: 2800,
      description: 'Roman trattoria in Trastevere.',
    ),
    NearbyPlace(
      id: 'rome-vatican',
      tripId: _trip,
      stopId: 'rome',
      name: 'Vatican Museums',
      type: PlaceType.activity,
      distanceMeters: 3100,
      description: 'Sistine Chapel and papal collections.',
    ),
    NearbyPlace(
      id: 'florence-trattoria',
      tripId: _trip,
      stopId: 'florence',
      name: 'Trattoria Mario',
      type: PlaceType.food,
      distanceMeters: 450,
      description: 'Family-run lunch spot near the market.',
    ),
    NearbyPlace(
      id: 'florence-duomo',
      tripId: _trip,
      stopId: 'florence',
      name: 'Duomo terrace',
      type: PlaceType.activity,
      distanceMeters: 750,
      description: 'Climb the dome for a view over the city.',
    ),
    NearbyPlace(
      id: 'florence-uffizi',
      tripId: _trip,
      stopId: 'florence',
      name: 'Uffizi Gallery',
      type: PlaceType.activity,
      distanceMeters: 1200,
      description: 'Renaissance masterpieces by the Arno.',
    ),
    NearbyPlace(
      id: 'venice-cicchetti',
      tripId: _trip,
      stopId: 'venice',
      name: 'Cantina Do Mori',
      type: PlaceType.food,
      distanceMeters: 600,
      description: 'Historic bacaro serving cicchetti.',
    ),
    NearbyPlace(
      id: 'venice-grand-canal',
      tripId: _trip,
      stopId: 'venice',
      name: 'Grand Canal at sunset',
      type: PlaceType.activity,
      distanceMeters: 1100,
      description: 'Watch the sunset from the Accademia bridge.',
    ),
  ];
}
