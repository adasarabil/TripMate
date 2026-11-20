import 'package:flutter_test/flutter_test.dart';
import 'package:tripmate/data/places_store.dart';

const _trip = 'interrail-summer';

void main() {
  test('Rome day 1 activities are ordered by time', () {
    final store = PlacesStore();
    final titles = store
        .activitiesFor(_trip, 'rome', DateTime(2026, 7, 12))
        .map((a) => a.title);
    expect(titles, [
      'Colosseum tour',
      'Lunch in Trastevere',
      'Trevi Fountain walk',
    ]);
  });

  test('adding and removing an activity is scoped by ID', () {
    final store = PlacesStore();
    final day = DateTime(2026, 7, 12);
    final id = store.addActivity(
      tripId: _trip,
      stopId: 'rome',
      start: DateTime(2026, 7, 12, 8, 30),
      title: '  Breakfast  ',
      location: '   ',
    );
    final other = store.addActivity(
      tripId: _trip,
      stopId: 'rome',
      start: DateTime(2026, 7, 12, 8, 30),
      title: 'Coffee',
    );
    expect(id, isNot(other));

    final added = store.activitiesFor(_trip, 'rome', day).first;
    expect(added.id, id);
    expect(added.title, 'Breakfast');
    expect(added.location, isNull);
    expect(store.activitiesFor(_trip, 'florence', day), isEmpty);

    expect(store.removeActivity(id), isTrue);
    expect(store.removeActivity(id), isFalse);
    expect(
      store.activitiesFor(_trip, 'rome', day).map((a) => a.id),
      isNot(contains(id)),
    );
  });

  test('log count follows added and removed logs', () {
    final store = PlacesStore();
    final before = store.logCountForTrips({_trip});
    expect(before, greaterThan(0));
    expect(store.logCountForTrips({'balkan-tour'}), 0);

    var notified = 0;
    store.addListener(() => notified++);
    final id = store.addLog(
      tripId: _trip,
      stopId: 'rome',
      name: 'Pantheon',
      type: PlaceType.activity,
      rating: 5,
      authorId: 'naz',
    );
    expect(store.logCountForTrips({_trip}), before + 1);
    expect(store.logsFor(_trip, 'rome').first.id, id);
    expect(
      store.logsFor(_trip, 'rome', type: PlaceType.food).map((log) => log.id),
      isNot(contains(id)),
    );

    store.removeLog(id);
    expect(store.logCountForTrips({_trip}), before);
    expect(notified, 2);
  });

  test('nearby places are sorted by distance and filtered by type', () {
    final store = PlacesStore();
    expect(
      store.nearbyFor(_trip, 'rome').map((p) => p.distanceMeters),
      [350, 900, 1400, 2800, 3100],
    );
    expect(
      store.nearbyFor(_trip, 'rome', type: PlaceType.food).map((p) => p.name),
      ['Gelateria del Teatro', 'Da Enzo al 29'],
    );
    expect(store.nearbyFor(_trip, 'unknown'), isEmpty);
  });

  test('a removed log no longer marks its nearby place', () {
    final store = PlacesStore();
    final log = store.logForPlace(_trip, 'rome-da-enzo');
    expect(log, isNotNull);
    store.removeLog(log!.id);
    expect(store.logForPlace(_trip, 'rome-da-enzo'), isNull);
  });

  test('a log added for a nearby place marks that place', () {
    final store = PlacesStore();
    expect(store.logForPlace(_trip, 'rome-trevi'), isNull);
    final id = store.addLog(
      tripId: _trip,
      stopId: 'rome',
      name: 'Trevi Fountain',
      type: PlaceType.activity,
      rating: 4,
      authorId: 'naz',
      placeId: 'rome-trevi',
    );
    expect(store.logForPlace(_trip, 'rome-trevi')?.id, id);
    expect(store.logForPlace('balkan-tour', 'rome-trevi'), isNull);
  });
}
