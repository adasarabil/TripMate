import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:tripmate/app/demo_session.dart';
import 'package:tripmate/app/step22_routes.dart';
import 'package:tripmate/data/expense_store.dart';
import 'package:tripmate/data/group_store.dart';
import 'package:tripmate/data/places_store.dart';
import 'package:tripmate/data/trip_store.dart';
import 'package:tripmate/ui/app_theme.dart';
import 'package:tripmate/ui/app_widgets.dart';

const _trip = 'interrail-summer';

Finder _filled(String label) => find.widgetWithText(FilledButton, label);

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<PlacesStore> _open(
  WidgetTester tester,
  String route,
  Object arguments,
) async {
  tester.view.physicalSize = const Size(430, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final places = PlacesStore();
  final navigator = GlobalKey<NavigatorState>();
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DemoSession()),
        ChangeNotifierProvider(create: (_) => TripStore()),
        ChangeNotifierProvider(create: (_) => GroupStore()),
        ChangeNotifierProvider.value(value: places),
        ChangeNotifierProvider(create: (_) => ExpenseStore()),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        navigatorKey: navigator,
        initialRoute: AppRoute.home,
        onGenerateRoute: AppRoute.generate,
      ),
    ),
  );
  navigator.currentState!.pushNamed<void>(route, arguments: arguments);
  await tester.pumpAndSettle();
  return places;
}

void main() {
  testWidgets('Itinerary validates and adds an activity to the chosen day', (
    tester,
  ) async {
    await _open(tester, AppRoute.itinerary, const CityStopArgs(_trip, 'rome'));

    expect(find.text('Hotel Roma'), findsOneWidget);
    expect(find.text('Day 3'), findsOneWidget);
    expect(find.text('Colosseum tour'), findsOneWidget);

    await _tap(tester, find.text('Day 2'));
    expect(find.text('Colosseum tour'), findsNothing);
    expect(find.text('Vatican Museums'), findsOneWidget);

    await _tap(tester, find.byTooltip('Add activity'));
    expect(find.text('Add Activity'), findsOneWidget);
    expect(find.text('Day 2 · 13 Jul'), findsOneWidget);

    await _tap(tester, _filled('Add to Itinerary'));
    expect(find.text('Please enter a title'), findsOneWidget);
    expect(find.text('Please choose a time'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('activity-title')), 'Gelato');
    await _tap(tester, find.byKey(const Key('activity-time')));
    await _tap(tester, find.text('OK'));
    expect(find.text('09:00'), findsOneWidget);
    await _tap(tester, _filled('Add to Itinerary'));

    expect(find.text('Add Activity'), findsNothing);
    final gelato = tester.getTopLeft(find.text('Gelato')).dy;
    final vatican = tester.getTopLeft(find.text('Vatican Museums')).dy;
    expect(gelato, lessThan(vatican));

    await _tap(tester, find.byTooltip('Remove Gelato'));
    await _tap(tester, find.text('Cancel'));
    expect(find.text('Gelato'), findsOneWidget);
    await _tap(tester, find.byTooltip('Remove Gelato'));
    await _tap(tester, _filled('Remove'));
    expect(find.text('Gelato'), findsNothing);
  });

  testWidgets('Places tab filters, logs and removes a place', (tester) async {
    final places = await _open(tester, AppRoute.tripDetail, _trip);
    final count = places.logCountForTrips({_trip});

    await _tap(tester, find.text('Places'));
    expect(find.text('Colosseum'), findsOneWidget);
    expect(find.text('Da Enzo al 29'), findsOneWidget);
    expect(
      find.byWidgetPredicate((w) => w is Image && w.image is NetworkImage),
      findsWidgets,
    );

    await _tap(tester, find.text('Food'));
    expect(find.text('Colosseum'), findsNothing);
    expect(find.text('Da Enzo al 29'), findsOneWidget);

    await _tap(tester, find.byTooltip('Add place log'));
    await _tap(tester, _filled('Save Log'));
    expect(find.text('Please enter a place name'), findsOneWidget);
    expect(find.text('Please choose a rating'), findsOneWidget);
    expect(places.logCountForTrips({_trip}), count);

    await tester.enterText(find.byKey(const Key('log-name')), 'Pantheon');
    await _tap(tester, find.text('Activity').last);
    await _tap(tester, find.byTooltip('4 stars'));
    await _tap(tester, _filled('Save Log'));

    expect(find.text('Add Place Log'), findsNothing);
    expect(find.text('Pantheon'), findsOneWidget);
    expect(find.text('Colosseum'), findsOneWidget);
    expect(places.logCountForTrips({_trip}), count + 1);

    await _tap(tester, find.byTooltip('Remove Pantheon'));
    await _tap(tester, _filled('Remove'));
    expect(find.text('Pantheon'), findsNothing);
    expect(places.logCountForTrips({_trip}), count);
  });

  testWidgets('Nearby lists places nearest first', (tester) async {
    await _open(tester, AppRoute.nearby, const CityStopArgs(_trip, 'rome'));

    expect(find.text('Nearby · Rome'), findsOneWidget);
    final names = [
      'Gelateria del Teatro',
      'Trevi Fountain',
      'Colosseum',
      'Da Enzo al 29',
      'Vatican Museums',
    ];
    final tops = [
      for (final name in names) tester.getTopLeft(find.text(name)).dy,
    ];
    expect(tops, orderedEquals([...tops]..sort()));
    expect(find.text('350 m'), findsOneWidget);
    expect(find.text('1.4 km'), findsOneWidget);

    await _tap(tester, find.text('Food'));
    expect(find.text('Trevi Fountain'), findsNothing);
    expect(find.text('Da Enzo al 29'), findsOneWidget);
  });

  testWidgets('A missing stop shows a safe fallback', (tester) async {
    await _open(
      tester,
      AppRoute.itinerary,
      const CityStopArgs(_trip, 'removed-stop'),
    );
    expect(
      find.text('This city stop is no longer part of the trip.'),
      findsOneWidget,
    );
    expect(find.byType(PendingStep22Screen), findsNothing);
  });
}
