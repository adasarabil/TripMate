import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:tripmate/data/trip_store.dart';
import 'package:tripmate/main.dart';

Finder _filled(String label) => find.widgetWithText(FilledButton, label);

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> _openTrips(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 780);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const TripMateApp());
  await _tap(tester, _filled('Log In'));
  await tester.enterText(
    find.byKey(const Key('auth-email')),
    'ada@example.com',
  );
  await tester.enterText(find.byKey(const Key('auth-password')), 'tripmate123');
  await _tap(tester, _filled('Log In'));
}

/// Opens the date picker of [field] and picks [day] of the shown month.
Future<void> _pickDay(WidgetTester tester, Finder field, int day) async {
  await _tap(tester, field);
  await tester.tap(
    find.descendant(of: find.byType(Dialog), matching: find.text('$day')),
  );
  await tester.pumpAndSettle();
  await _tap(tester, find.text('OK'));
}

TripStore _store(WidgetTester tester) =>
    tester.element(find.byType(Scaffold).last).read<TripStore>();

void main() {
  testWidgets(
    'New Trip shows inline errors, Cancel saves nothing, Confirm opens Route',
    (tester) async {
      await _openTrips(tester);
      await _tap(tester, find.byTooltip('Create trip'));
      expect(find.text('New Trip'), findsOneWidget);

      await _tap(tester, _filled('Create Trip'));
      expect(find.text('Enter a trip title'), findsOneWidget);
      expect(find.text('Select a travel group'), findsOneWidget);
      expect(find.text('Select a start date'), findsOneWidget);
      expect(find.text('Select an end date'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);

      await tester.enterText(find.byKey(const Key('trip-title')), 'Lisbon');
      await _tap(tester, find.byType(DropdownButtonFormField<String>).first);
      await _tap(tester, find.text('Interrail Gang').last);
      await _pickDay(tester, find.byKey(const Key('trip-start')), 20);
      await _pickDay(tester, find.byKey(const Key('trip-end')), 18);
      expect(find.text('20/07/2026'), findsOneWidget);

      await _tap(tester, _filled('Create Trip'));
      expect(find.text('End date must be after start date'), findsOneWidget);
      expect(find.text('Enter a trip title'), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);

      await _pickDay(tester, find.byKey(const Key('trip-end')), 25);
      await _tap(tester, _filled('Create Trip'));
      expect(find.text('Create trip?'), findsOneWidget);
      await _tap(tester, find.text('Cancel'));
      expect(find.text('New Trip'), findsOneWidget);
      expect(_store(tester).trips, hasLength(3));

      await _tap(tester, _filled('Create Trip'));
      await _tap(tester, _filled('Confirm'));
      expect(_store(tester).trips, hasLength(4));
      final trip = _store(tester).trips.last;
      expect(trip.title, 'Lisbon');
      expect(trip.start, DateTime(2026, 7, 20));
      expect(trip.end, DateTime(2026, 7, 25));
      expect(trip.currencyCode, 'EUR');

      // Route tab of the new, empty trip.
      expect(find.text('Lisbon'), findsOneWidget);
      expect(find.text('No cities yet'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Add city'), findsOneWidget);
    },
  );

  testWidgets('Route total, leg filter, and adding/removing a cheaper option', (
    tester,
  ) async {
    await _openTrips(tester);
    await _tap(tester, find.text('Interrail Summer'));
    expect(find.text('Rome'), findsOneWidget);
    expect(find.text('Florence'), findsOneWidget);
    expect(find.text('Venice'), findsOneWidget);
    expect(find.textContaining('€31'), findsOneWidget);
    expect(find.text('Bus · €19 · 3h 15m'), findsOneWidget);
    expect(find.text('Train · €12 · 2h 5m'), findsOneWidget);

    await _tap(tester, find.byKey(const ValueKey('leg-rome-florence')));
    expect(find.text('Rome → Florence'), findsOneWidget);
    expect(find.text('Leg 1 of 2 · 14 Jul'), findsOneWidget);
    expect(find.text('CHEAPEST'), findsOneWidget);
    expect(find.text('Bus · FlixBus'), findsOneWidget);

    // A filtered list must not mislabel a non-cheapest option.
    await _tap(tester, find.text('Train'));
    expect(find.text('Bus · FlixBus'), findsNothing);
    expect(find.text('Train · Italo'), findsOneWidget);
    expect(find.text('CHEAPEST'), findsNothing);

    await _tap(tester, find.byTooltip('Add transport option'));
    expect(find.text('Add Transport Option'), findsOneWidget);
    await _tap(tester, _filled('Save Option'));
    expect(find.text('Enter a company or note'), findsOneWidget);
    expect(find.text('Enter a price'), findsOneWidget);
    expect(find.text('Select a departure time'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('transport-price')), '0');
    await tester.pump();
    expect(find.text('Price must be a positive number'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('transport-price')), '15,5');
    await tester.pump();
    expect(find.text('Use a dot for decimals, e.g. 19.50'), findsOneWidget);

    await _tap(tester, find.text('Bus'));
    await tester.enterText(
      find.byKey(const Key('transport-company')),
      'Night bus',
    );
    await tester.enterText(find.byKey(const Key('transport-price')), '15');
    await tester.enterText(
      find.byKey(const Key('transport-duration')),
      '3h 30m',
    );
    await _tap(tester, find.byKey(const Key('transport-departure')));
    await _tap(tester, find.text('OK'));
    await _tap(tester, _filled('Save Option'));

    // Back on 10: filter returns to All so the new bus shows once.
    expect(find.text('Rome → Florence'), findsOneWidget);
    expect(find.text('Bus · Night bus'), findsOneWidget);
    expect(find.text('Bus · FlixBus'), findsOneWidget);
    expect(find.text('CHEAPEST'), findsOneWidget);
    expect(find.text('€27'), findsOneWidget);

    await _tap(tester, find.byTooltip('Remove Night bus'));
    await _tap(tester, find.text('Cancel'));
    expect(find.text('Bus · Night bus'), findsOneWidget);
    await _tap(tester, find.byTooltip('Remove Night bus'));
    await _tap(tester, _filled('Remove'));
    expect(find.text('Bus · Night bus'), findsNothing);
    expect(find.text('€31'), findsOneWidget);
  });

  testWidgets('City stop add validates dates, edit fills, delete removes', (
    tester,
  ) async {
    await _openTrips(tester);
    await _tap(tester, find.text('Interrail Summer'));

    await _tap(tester, find.widgetWithText(OutlinedButton, 'Add city'));
    expect(find.text('Add City Stop'), findsOneWidget);
    expect(find.text('Delete Stop'), findsNothing);
    await _tap(tester, _filled('Save Stop'));
    expect(find.text('Enter a city'), findsOneWidget);
    expect(find.text('Enter a hotel name'), findsOneWidget);
    expect(find.text('Select an arrival date'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('stop-city')), 'Milan');
    await tester.enterText(
      find.byKey(const Key('stop-hotel-name')),
      'Milano Inn',
    );
    await _pickDay(tester, find.byKey(const Key('stop-arrival')), 18);
    await _pickDay(tester, find.byKey(const Key('stop-departure')), 17);
    await _tap(tester, _filled('Save Stop'));
    expect(find.text('Departure can’t be before arrival'), findsOneWidget);
    expect(find.text('Add City Stop'), findsOneWidget);

    await _pickDay(tester, find.byKey(const Key('stop-departure')), 19);
    await _tap(tester, _filled('Save Stop'));
    expect(find.text('Milan'), findsOneWidget);
    expect(find.text('Add transport option'), findsOneWidget);
    expect(find.textContaining('1 leg missing'), findsOneWidget);

    await _tap(tester, find.byTooltip('Edit Rome'));
    expect(find.text('Edit City Stop'), findsOneWidget);
    expect(find.text('Hotel Roma'), findsOneWidget);
    await _tap(tester, find.widgetWithText(OutlinedButton, 'Delete Stop'));
    await _tap(tester, find.text('Cancel'));
    expect(find.text('Edit City Stop'), findsOneWidget);
    await _tap(tester, find.widgetWithText(OutlinedButton, 'Delete Stop'));
    await _tap(tester, _filled('Delete'));

    expect(find.text('Interrail Summer'), findsOneWidget);
    expect(find.text('Rome'), findsNothing);
    expect(find.text('Florence'), findsOneWidget);
    expect(find.text('Bus · €19 · 3h 15m'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Remove city on the route asks first', (tester) async {
    await _openTrips(tester);
    await _tap(tester, find.text('Interrail Summer'));
    await _tap(tester, find.byTooltip('Remove Venice'));
    await _tap(tester, find.text('Cancel'));
    expect(find.text('Venice'), findsOneWidget);
    await _tap(tester, find.byTooltip('Remove Venice'));
    await _tap(tester, _filled('Remove'));
    expect(find.text('Venice'), findsNothing);
    expect(find.textContaining('€19'), findsWidgets);
  });

  for (final size in [const Size(320, 568), const Size(430, 932)]) {
    testWidgets(
      'trip forms fit ${size.width.toInt()} × ${size.height.toInt()} with keyboard',
      (tester) async {
        await _openTrips(tester);
        tester.view.physicalSize = size;
        await tester.pumpAndSettle();
        const keyboard = 270.0;

        Future<void> expectReachable(Finder field, Finder submit) async {
          await tester.showKeyboard(field);
          tester.view.viewInsets = const FakeViewPadding(bottom: keyboard);
          await tester.pumpAndSettle();
          // Scroll like a user would; the list builds the button lazily.
          await tester.scrollUntilVisible(
            submit,
            80,
            scrollable: find
                .descendant(
                  of: find.byType(ListView),
                  matching: find.byType(Scrollable),
                )
                .first,
          );
          await tester.ensureVisible(submit);
          await tester.pumpAndSettle();
          expect(
            tester.getBottomLeft(submit).dy,
            lessThanOrEqualTo(size.height - keyboard),
          );
          tester.view.resetViewInsets();
          await tester.pumpAndSettle();
        }

        await _tap(tester, find.text('Interrail Summer'));
        await _tap(tester, find.widgetWithText(OutlinedButton, 'Add city'));
        await _tap(tester, _filled('Save Stop'));
        await expectReachable(
          find.byKey(const Key('stop-hotel-address')),
          _filled('Save Stop'),
        );
        await _tap(tester, find.byType(BackButton));

        await _tap(tester, find.byKey(const ValueKey('leg-rome-florence')));
        await _tap(tester, find.byTooltip('Add transport option'));
        await _tap(tester, _filled('Save Option'));
        await expectReachable(
          find.byKey(const Key('transport-duration')),
          _filled('Save Option'),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
