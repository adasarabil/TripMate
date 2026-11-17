import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:tripmate/app/demo_session.dart';
import 'package:tripmate/app/step22_routes.dart';
import 'package:tripmate/main.dart';
import 'package:tripmate/ui/app_widgets.dart';

final _email = find.byKey(const Key('auth-email'));
final _password = find.byKey(const Key('auth-password'));
final _confirmation = find.byKey(const Key('auth-confirm-password'));

Finder _filled(String label) => find.widgetWithText(FilledButton, label);

NavigatorState _navigator(WidgetTester tester) =>
    tester.state<NavigatorState>(find.byType(Navigator));

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> _enterLogin(
  WidgetTester tester, {
  String password = 'tripmate123',
}) async {
  await tester.enterText(_email, 'ada@example.com');
  await tester.enterText(_password, password);
}

Future<void> _openTrips(WidgetTester tester) async {
  await tester.pumpWidget(const TripMateApp());
  await _tap(tester, _filled('Log In'));
  await _enterLogin(tester);
  await _tap(tester, _filled('Log In'));
}

void main() {
  testWidgets(
    'Welcome to Log In validates, reveals password, and opens My Trips',
    (tester) async {
      await tester.pumpWidget(const TripMateApp());
      final image = tester.widget<AppImage>(find.byType(AppImage));
      expect(image.asset, AppAssets.welcome);
      final welcome = tester.element(find.text('TripMate'));
      expect(Theme.of(welcome).textTheme.headlineMedium?.fontFamily, 'Inter');
      for (final asset in [
        AppAssets.welcome,
        AppAssets.joinGroup,
        AppAssets.tripCover,
        AppAssets.imageFallback,
        'assets/fonts/Inter-Regular.ttf',
        'assets/fonts/Inter-SemiBold.ttf',
        'assets/fonts/Inter-Bold.ttf',
      ]) {
        expect((await rootBundle.load(asset)).lengthInBytes, greaterThan(0));
      }

      await _tap(tester, _filled('Log In'));
      await _enterLogin(tester, password: '1234');
      await _tap(tester, _filled('Log In'));
      expect(
        find.text('Password must be at least 6 characters'),
        findsOneWidget,
      );

      final editable = find.descendant(
        of: _password,
        matching: find.byType(EditableText),
      );
      expect(tester.widget<EditableText>(editable).obscureText, isTrue);
      await _tap(tester, find.byTooltip('Show password'));
      expect(tester.widget<EditableText>(editable).obscureText, isFalse);
      await _tap(tester, find.byTooltip('Hide password'));
      expect(tester.widget<EditableText>(editable).obscureText, isTrue);

      await _enterLogin(tester);
      await _tap(tester, _filled('Log In'));
      expect(find.text('My Trips'), findsOneWidget);
      expect(find.text('Hi, Ada!'), findsOneWidget);
      expect(find.text('2 upcoming trips'), findsOneWidget);
      expect(find.text('Rome → Florence → Venice'), findsOneWidget);
      expect(find.text('12–19 Jul · 5 members'), findsOneWidget);
      expect(find.text('Apr · 4 members'), findsOneWidget);
      expect(find.byType(Card), findsNWidgets(3));
      expect(_navigator(tester).canPop(), isFalse);
    },
  );

  testWidgets('Sign Up shows field errors and starts the same demo session', (
    tester,
  ) async {
    await tester.pumpWidget(const TripMateApp());
    await _tap(tester, find.widgetWithText(OutlinedButton, 'Sign Up'));
    final username = find.byKey(const Key('auth-username'));
    await tester.enterText(username, '  ');
    await tester.enterText(_email, 'ada@');
    await tester.enterText(_password, 'tripmate123');
    await tester.enterText(_confirmation, 'wrong');
    await _tap(tester, _filled('Create Account'));
    expect(find.text('Enter a username'), findsOneWidget);
    expect(find.text('Enter a valid email address'), findsOneWidget);
    expect(find.text('Passwords do not match'), findsOneWidget);

    await tester.enterText(username, 'ada_demo');
    await tester.enterText(_email, 'ada@example.com');
    await tester.enterText(_confirmation, 'tripmate123');
    await _tap(tester, _filled('Create Account'));
    expect(find.text('Hi, Ada!'), findsOneWidget);
    expect(_navigator(tester).canPop(), isFalse);
  });

  testWidgets('switching auth forms keeps one back step to Welcome', (
    tester,
  ) async {
    await tester.pumpWidget(const TripMateApp());
    await _tap(tester, _filled('Log In'));
    for (var i = 0; i < 2; i++) {
      await _tap(tester, find.text("Don't have an account? Sign up"));
      expect(find.text('Create account'), findsOneWidget);
      await _tap(tester, find.text('Already have an account? Log in'));
      expect(find.text('Welcome back'), findsOneWidget);
    }
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('TripMate'), findsOneWidget);
    expect(_navigator(tester).canPop(), isFalse);
  });

  testWidgets('root tabs and avatar use shared state and logout resets it', (
    tester,
  ) async {
    await _openTrips(tester);
    await _tap(tester, find.text('Groups'));
    expect(find.text('My Groups is in development.'), findsOneWidget);
    await _tap(tester, find.text('Trips'));
    await _tap(tester, find.byTooltip('Open Profile'));
    expect(find.text('Profile is in development.'), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(_navigator(tester).canPop(), isFalse);

    final context = tester.element(find.byType(PendingStep22Screen));
    final session = context.read<DemoSession>();
    expect(session.currentTab, AppMainTab.profile);
    session.setThemeMode(ThemeMode.dark);
    await tester.pumpAndSettle();
    expect(Theme.of(context).brightness, Brightness.dark);
    AppRoute.logOut(context);
    await tester.pumpAndSettle();
    expect(find.text('TripMate'), findsOneWidget);
    expect(session.currentTab, AppMainTab.trips);
    expect(_navigator(tester).canPop(), isFalse);
  });

  testWidgets(
    'card removal honors Cancel and updates the correct trip on Confirm',
    (tester) async {
      await _openTrips(tester);
      await _tap(tester, find.byTooltip('Remove Weekend in Izmir'));
      await _tap(tester, find.text('Cancel'));
      expect(find.text('Weekend in Izmir'), findsOneWidget);
      expect(find.text('2 upcoming trips'), findsOneWidget);

      await _tap(tester, find.byTooltip('Remove Weekend in Izmir'));
      await _tap(tester, _filled('Confirm'));
      expect(find.text('Weekend in Izmir'), findsNothing);
      expect(find.text('Interrail Summer'), findsOneWidget);
      expect(find.text('Balkan Tour'), findsOneWidget);
      expect(find.text('1 upcoming trip'), findsOneWidget);
      expect(find.byType(Card), findsNWidgets(2));
    },
  );

  testWidgets(
    'trip detail keeps its selected tab across back and can remove the trip',
    (tester) async {
      await _openTrips(tester);
      await _tap(tester, find.text('Interrail Summer'));
      expect(find.text('Route is in development.'), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsNothing);

      await _tap(tester, find.text('Expenses'));
      _navigator(tester)
          .pushNamed<void>(AppRoute.addExpense, arguments: 'interrail-summer');
      await tester.pumpAndSettle();
      expect(find.text('Add Expense is in development.'), findsOneWidget);
      await _tap(tester, find.byType(BackButton));
      expect(find.text('Expenses is in development.'), findsOneWidget);

      await _tap(tester, find.byTooltip('Trip options'));
      await _tap(tester, find.text('Remove trip'));
      await _tap(tester, _filled('Confirm'));
      expect(find.text('My Trips'), findsOneWidget);
      expect(find.text('Interrail Summer'), findsNothing);
      expect(_navigator(tester).canPop(), isFalse);

      await _tap(tester, find.text('Weekend in Izmir'));
      expect(find.text('Route is in development.'), findsOneWidget);
    },
  );

  testWidgets(
    'New Trip return opens the matching detail and keeps one card per ID',
    (tester) async {
      await _openTrips(tester);
      await _tap(tester, find.byTooltip('Create trip'));
      expect(find.text('New Trip is in development.'), findsOneWidget);
      await _tap(tester, find.byType(BackButton));
      expect(find.byType(Card), findsNWidgets(3));

      await _tap(tester, find.byTooltip('Create trip'));
      _navigator(tester).pop<String>('weekend-in-izmir');
      await tester.pumpAndSettle();
      expect(find.text('Weekend in Izmir'), findsOneWidget);
      expect(find.text('Route is in development.'), findsOneWidget);
      await _tap(tester, find.byType(BackButton));
      expect(find.byType(Card), findsNWidgets(3));
    },
  );

  testWidgets(
    'unknown routes, wrong payloads, and missing IDs have a safe return',
    (tester) async {
      await _openTrips(tester);
      for (final (route, arguments) in <(String, Object?)>[
        ('/unknown', null),
        (AppRoute.editCityStop, 'wrong-type'),
        (AppRoute.tripDetail, 'missing'),
        (AppRoute.groupDetail, 'missing'),
      ]) {
        _navigator(tester).pushNamed<void>(route, arguments: arguments);
        await tester.pumpAndSettle();
        expect(find.text('Page unavailable'), findsOneWidget);
        await _tap(tester, find.text('Go back'));
        expect(find.text('My Trips'), findsOneWidget);
      }
    },
  );

  for (final size in [
    const Size(320, 568),
    const Size(390, 780),
    const Size(430, 932),
  ]) {
    testWidgets(
      'portrait ${size.width.toInt()} × ${size.height.toInt()} keeps CTAs reachable',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        tester.view.viewPadding = const FakeViewPadding(top: 24);
        addTearDown(tester.view.reset);

        const keyboardHeight = 270.0;
        Future<void> expectKeyboardWithReachable(Finder submit) async {
          tester.view.viewInsets = const FakeViewPadding(
            bottom: keyboardHeight,
          );
          await tester.pumpAndSettle();
          await tester.ensureVisible(submit);
          await tester.pumpAndSettle();
          expect(
            tester.getBottomLeft(submit).dy,
            lessThanOrEqualTo(size.height - keyboardHeight),
          );
          expect(tester.testTextInput.isVisible, isTrue);
        }

        await tester.pumpWidget(const TripMateApp());
        final logIn = _filled('Log In');
        await _tap(tester, logIn);
        await tester.showKeyboard(_password);
        await expectKeyboardWithReachable(logIn);
        tester.view.resetViewInsets();
        await tester.pumpAndSettle();
        await _tap(tester, find.byType(BackButton));

        final signUp = find.widgetWithText(OutlinedButton, 'Sign Up');
        await _tap(tester, signUp);
        for (final (field, value) in [
          (find.byKey(const Key('auth-username')), 'ada_demo'),
          (_email, 'ada@example.com'),
          (_password, 'tripmate123'),
          (_confirmation, 'tripmate123'),
        ]) {
          await tester.ensureVisible(field);
          await tester.enterText(field, value);
        }

        final submit = _filled('Create Account');
        await expectKeyboardWithReachable(submit);
        await _tap(tester, submit);
        tester.view.resetViewInsets();
        await tester.pumpAndSettle();

        final fab = find.byType(FloatingActionButton);
        expect(fab, findsOneWidget);
        await tester.drag(find.byType(ListView), const Offset(0, -500));
        await tester.pumpAndSettle();
        final lastCard = find.ancestor(
          of: find.text('Balkan Tour'),
          matching: find.byType(Card),
        );
        expect(
          tester.getBottomRight(lastCard).dy,
          lessThan(tester.getTopRight(fab).dy),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
