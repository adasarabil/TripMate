import 'package:flutter_test/flutter_test.dart';
import 'package:tripmate/data/trip_store.dart';
import 'package:tripmate/features/trips/trip_format.dart';

const _trip = 'interrail-summer';

void main() {
  group('route cost', () {
    test('seed legs use their cheapest option and total €31', () {
      final store = TripStore();
      final legs = store.legsOf(_trip);
      expect(legs.map((leg) => '${leg.from.id}>${leg.to.id}'), [
        'rome>florence',
        'florence>venice',
      ]);
      expect(legs[0].cheapest?.priceMinor, 1900);
      expect(legs[1].cheapest?.priceMinor, 1200);

      final summary = store.routeSummary(_trip);
      expect(summary.totalMinor, 3100);
      expect(summary.isComplete, isTrue);
      expect(TripFormat.money(summary.totalMinor, 'EUR'), '€31');
    });

    test('reorder recomputes directed adjacency and flags missing legs', () {
      final store = TripStore();
      // Rome, Florence, Venice → Venice, Rome, Florence
      store.moveStop(_trip, 2, 0);
      final trip = store.byId(_trip)!;
      expect(trip.stops.map((s) => s.id), ['venice', 'rome', 'florence']);
      // Dates are not rewritten by a reorder.
      expect(trip.stops.first.arrival, DateTime(2026, 7, 16));

      final summary = store.routeSummary(_trip);
      expect(summary.legCount, 2);
      expect(summary.missingLegCount, 1); // venice → rome has no options
      expect(summary.totalMinor, 1900); // only rome → florence counts
      expect(store.legFor(_trip, 'florence', 'venice'), isNull);
    });

    test('cheaper option changes the cheapest and removal restores it', () {
      final store = TripStore();
      final id = store.addTransportOption(
        tripId: _trip,
        fromStopId: 'rome',
        toStopId: 'florence',
        mode: TransportMode.train,
        company: 'Regional',
        priceMinor: 1500,
        durationMinutes: 210,
        departure: DateTime(2026, 7, 14, 6),
      );
      expect(id, isNotNull);
      expect(store.cheapestForLeg(_trip, 'rome', 'florence')?.id, id);
      expect(store.routeSummary(_trip).totalMinor, 2700);

      expect(store.removeTransportOption(id!), isTrue);
      expect(
        store.cheapestForLeg(_trip, 'rome', 'florence')?.id,
        'rome-florence-bus',
      );
      expect(store.routeSummary(_trip).totalMinor, 3100);
    });

    test('a price tie keeps the earlier option as cheapest', () {
      final store = TripStore();
      store.addTransportOption(
        tripId: _trip,
        fromStopId: 'rome',
        toStopId: 'florence',
        mode: TransportMode.train,
        company: 'Same price',
        priceMinor: 1900,
        durationMinutes: 100,
        departure: DateTime(2026, 7, 14, 7),
      );
      expect(
        store.cheapestForLeg(_trip, 'rome', 'florence')?.id,
        'rome-florence-bus',
      );
    });

    test('options are rejected for non-adjacent legs or bad values', () {
      final store = TripStore();
      String? add(String from, String to, {int price = 100, int min = 10}) =>
          store.addTransportOption(
            tripId: _trip,
            fromStopId: from,
            toStopId: to,
            mode: TransportMode.bus,
            company: 'X',
            priceMinor: price,
            durationMinutes: min,
            departure: DateTime(2026, 7, 14),
          );
      expect(add('rome', 'venice'), isNull);
      expect(add('florence', 'rome'), isNull);
      expect(add('rome', 'florence', price: 0), isNull);
      expect(add('rome', 'florence', min: 0), isNull);
    });
  });

  group('stops and trips', () {
    test('removing a stop drops its options from the total', () {
      final store = TripStore();
      expect(store.removeStop(_trip, 'florence'), isTrue);
      expect(store.optionsForLeg(_trip, 'rome', 'florence'), isEmpty);
      final summary = store.routeSummary(_trip);
      expect(summary.legCount, 1); // rome → venice
      expect(summary.missingLegCount, 1);
      expect(summary.totalMinor, 0);
    });

    test('saveStop adds with a fresh ID and updates in place', () {
      final store = TripStore();
      final id = store.saveStop(
        _trip,
        name: ' Milan ',
        arrival: DateTime(2026, 7, 18),
        departure: DateTime(2026, 7, 19),
        hotelName: 'Milano Inn',
        hotelAddress: 'Milan, Italy',
      );
      expect(id, isNotNull);
      expect(store.byId(_trip)!.stops.last.name, 'Milan');

      store.saveStop(
        _trip,
        stopId: 'rome',
        name: 'Roma',
        arrival: DateTime(2026, 7, 12),
        departure: DateTime(2026, 7, 13),
        hotelName: 'Hotel Roma',
        hotelAddress: 'Rome, Italy',
      );
      final stops = store.byId(_trip)!.stops;
      expect(stops.first.id, 'rome');
      expect(stops.first.name, 'Roma');
      expect(stops.length, 4);
      // Rome kept its ID, so its leg options are still attached.
      expect(store.cheapestForLeg(_trip, 'rome', 'florence'), isNotNull);
    });

    test('addTrip stores the chosen values under a unique ID', () {
      final store = TripStore();
      final a = store.addTrip(
        title: '  Lisbon  ',
        groupId: 'interrail-gang',
        start: DateTime(2026, 8, 1),
        end: DateTime(2026, 8, 5),
        currencyCode: 'USD',
      );
      final b = store.addTrip(
        title: 'Lisbon',
        groupId: 'interrail-gang',
        start: DateTime(2026, 8, 1),
        end: DateTime(2026, 8, 5),
        currencyCode: 'EUR',
      );
      expect(a, isNot(b));
      final trip = store.byId(a)!;
      expect(trip.title, 'Lisbon');
      expect(trip.currencyCode, 'USD');
      expect(trip.stops, isEmpty);
      expect(store.routeSummary(a).legCount, 0);
    });
  });

  group('input parsing', () {
    test('money accepts dot decimals only', () {
      expect(parseMoneyMinor('19'), 1900);
      expect(parseMoneyMinor('19.5'), 1950);
      expect(parseMoneyMinor('19.05'), 1905);
      expect(parseMoneyMinor('19,50'), isNull);
      expect(parseMoneyMinor('-3'), isNull);
      expect(parseMoneyMinor('abc'), isNull);
      expect(parseMoneyMinor('1.234'), isNull);
    });

    test('duration accepts minutes, h/m and clock forms', () {
      expect(parseDurationMinutes('95'), 95);
      expect(parseDurationMinutes('1h 35m'), 95);
      expect(parseDurationMinutes('2h'), 120);
      expect(parseDurationMinutes('45m'), 45);
      expect(parseDurationMinutes('1:35'), 95);
      expect(parseDurationMinutes('soon'), isNull);
      expect(TripFormat.duration(95), '1h 35m');
    });
  });
}
