import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:tripmate/app/demo_session.dart';
import 'package:tripmate/app/step22_routes.dart';
import 'package:tripmate/data/group_store.dart';
import 'package:tripmate/data/trip_store.dart';
import 'package:tripmate/main.dart';

Finder _filled(String label) => find.widgetWithText(FilledButton, label);

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> _openGroups(
  WidgetTester tester, {
  Size size = const Size(390, 780),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const TripMateApp());
  await _tap(tester, _filled('Log In'));
  await tester.enterText(
    find.byKey(const Key('auth-email')),
    'ada@example.com',
  );
  await tester.enterText(find.byKey(const Key('auth-password')), 'tripmate123');
  await _tap(tester, _filled('Log In'));
  await _tap(tester, find.text('Groups'));
}

BuildContext _ctx(WidgetTester tester) =>
    tester.element(find.byType(Scaffold).last);

void main() {
  testWidgets('My Groups lists seeds with member and trip counts', (
    tester,
  ) async {
    await _openGroups(tester);
    expect(find.text('My Groups'), findsOneWidget);
    expect(find.text('Interrail Gang'), findsOneWidget);
    expect(find.text('5 members · 1 trip'), findsOneWidget);
    expect(find.text('Weekend Izmir'), findsOneWidget);
    expect(find.text('Balkan Tour'), findsOneWidget);
    expect(find.text('Cappadocia Crew'), findsNothing);

    // Removing a trip elsewhere updates the trip count here.
    _ctx(tester).read<TripStore>().removeTrip('interrail-summer');
    await tester.pumpAndSettle();
    expect(find.text('5 members · 0 trips'), findsOneWidget);
  });

  testWidgets('Create Group validates the name and opens the new detail', (
    tester,
  ) async {
    await _openGroups(tester);
    await _tap(tester, find.byTooltip('Create Group'));
    await tester.enterText(find.byType(TextFormField), '   ');
    await _tap(tester, _filled('Create Group'));
    expect(find.text('Enter a group name'), findsOneWidget);
    expect(_ctx(tester).read<GroupStore>().visibleGroups, hasLength(3));

    await tester.enterText(find.byType(TextFormField), '  Ski Trip ');
    await _tap(tester, _filled('Create Group'));
    expect(find.widgetWithText(AppBar, 'Ski Trip'), findsOneWidget);
    expect(find.text('MEMBERS (1)'), findsOneWidget);
    expect(find.text('No trips for this group yet.'), findsOneWidget);

    await _tap(tester, find.byType(BackButton));
    expect(find.text('1 member · 0 trips'), findsOneWidget);
    expect(_ctx(tester).read<GroupStore>().visibleGroups, hasLength(4));
  });

  testWidgets('leave hides a group, Cancel keeps it, code joins it again', (
    tester,
  ) async {
    await _openGroups(tester);
    await _tap(tester, find.byTooltip('Leave Weekend Izmir'));
    await _tap(tester, find.text('Cancel'));
    expect(find.text('Weekend Izmir'), findsOneWidget);

    await _tap(tester, find.byTooltip('Leave Weekend Izmir'));
    await _tap(tester, _filled('Leave'));
    expect(find.text('Weekend Izmir'), findsNothing);
    final store = _ctx(tester).read<GroupStore>();
    expect(store.byId('weekend-izmir')?.name, 'Weekend Izmir');
    expect(
      _ctx(tester).read<TripStore>().byId('weekend-in-izmir')?.groupId,
      'weekend-izmir',
    );

    await _tap(tester, find.text('Join with invite code'));
    await tester.enterText(find.byType(TextFormField), 'trp-iz3r');
    await _tap(tester, _filled('Join Group'));
    expect(find.widgetWithText(AppBar, 'Weekend Izmir'), findsOneWidget);
  });

  testWidgets('Join Group handles empty, unknown, member and valid codes', (
    tester,
  ) async {
    await _openGroups(tester);
    await _tap(tester, find.text('Join with invite code'));
    expect(find.text('Got an invite code?'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);

    await _tap(tester, _filled('Join Group'));
    expect(find.text('Enter an invite code'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'TRP-0000');
    await _tap(tester, _filled('Join Group'));
    expect(find.text('No group found with this code'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'TRP-4K9X');
    await _tap(tester, _filled('Join Group'));
    expect(
      find.text('You are already a member of Interrail Gang'),
      findsOneWidget,
    );
    expect(find.text('Got an invite code?'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), ' trp-7m2q ');
    await _tap(tester, _filled('Join Group'));
    expect(find.widgetWithText(AppBar, 'Cappadocia Crew'), findsOneWidget);
    expect(find.text('MEMBERS (3)'), findsOneWidget);

    await _tap(tester, find.byType(BackButton));
    expect(find.text('Cappadocia Crew'), findsOneWidget);
    expect(find.text('3 members · 0 trips'), findsOneWidget);
  });

  testWidgets('Group Detail copies, shares, invites and removes', (
    tester,
  ) async {
    String? clipboard;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboard = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    // A null reply makes share_plus report "unavailable", as on a platform
    // without a native share sheet.
    String? shared;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/share'),
      (call) async {
        shared = (call.arguments as Map)['text'] as String?;
        return null;
      },
    );

    await _openGroups(tester);
    await _tap(tester, find.text('Interrail Gang'));
    expect(find.text('TRP-4K9X'), findsOneWidget);
    expect(find.text('MEMBERS (5)'), findsOneWidget);

    await _tap(tester, find.widgetWithText(OutlinedButton, 'Copy'));
    expect(clipboard, 'TRP-4K9X');
    expect(find.text('Invite code TRP-4K9X copied.'), findsOneWidget);

    // Without a native share sheet the in-app share sheet opens.
    await _tap(tester, _filled('Share'));
    expect(shared, contains('TRP-4K9X'));
    expect(find.text('Share invite'), findsOneWidget);
    await _tap(tester, _filled('Copy invite code'));
    expect(find.text('Share invite'), findsNothing);

    final invite = find.widgetWithText(FilledButton, 'Invite');
    await _tap(tester, invite);
    expect(find.text('Enter a username'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Username'),
      'nobody',
    );
    await _tap(tester, invite);
    expect(find.text('No user found with @nobody'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Username'),
      '@nazzagli',
    );
    await _tap(tester, invite);
    expect(find.text('@nazzagli is already a member'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Username'),
      ' @DemoElif',
    );
    await _tap(tester, invite);
    expect(find.text('MEMBERS (6)'), findsOneWidget);
    expect(find.text('@demoelif'), findsOneWidget);

    // Ada owns the group: no X on her own row, X on the others.
    expect(find.byTooltip('Remove Ada Derviş Sarabil'), findsNothing);
    await _tap(tester, find.byTooltip('Remove Elif'));
    await _tap(tester, _filled('Remove'));
    expect(find.text('MEMBERS (5)'), findsOneWidget);
    expect(find.text('@demoelif'), findsNothing);

    await _tap(tester, find.text('Interrail Summer'));
    expect(find.text('Florence'), findsWidgets);
    await _tap(tester, find.byType(BackButton));

    await _tap(tester, find.byTooltip('Remove Interrail Summer'));
    expect(find.textContaining('also removed from My Trips'), findsOneWidget);
    await _tap(tester, _filled('Confirm'));
    expect(find.text('No trips for this group yet.'), findsOneWidget);
    expect(_ctx(tester).read<TripStore>().byId('interrail-summer'), isNull);

    await _tap(tester, find.byTooltip('Group options'));
    await _tap(tester, find.text('Leave group'));
    await _tap(tester, _filled('Leave'));
    expect(find.text('My Groups'), findsOneWidget);
    expect(find.text('Interrail Gang'), findsNothing);
  });

  testWidgets('unknown or left group IDs show a safe state', (tester) async {
    await _openGroups(tester);
    final context = _ctx(tester);
    Navigator.pushNamed<void>(context, AppRoute.groupDetail, arguments: 'x');
    await tester.pumpAndSettle();
    expect(find.text('Interrail Gang'), findsNothing);
    Navigator.pop(_ctx(tester));
    await tester.pumpAndSettle();

    context.read<GroupStore>().leaveGroup('balkan-tour');
    Navigator.pushNamed<void>(
      context,
      AppRoute.groupDetail,
      arguments: 'balkan-tour',
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining('no longer a member of Balkan Tour'),
      findsOneWidget,
    );
    await _tap(tester, _filled('Back to My Groups'));
    expect(find.text('My Groups'), findsOneWidget);
  });

  testWidgets('Settings changes theme, language, notifications and about', (
    tester,
  ) async {
    await _openGroups(tester);
    Navigator.pushNamed<void>(_ctx(tester), AppRoute.settings);
    await tester.pumpAndSettle();
    final session = _ctx(tester).read<DemoSession>();
    expect(find.text('PREFERENCES'), findsOneWidget);
    expect(find.text('ABOUT'), findsOneWidget);

    await _tap(tester, find.text('Theme'));
    await _tap(tester, find.text('Dark'));
    expect(session.themeMode, ThemeMode.dark);
    expect(Theme.of(_ctx(tester)).brightness, Brightness.dark);
    await _tap(tester, find.text('Theme'));
    await _tap(tester, find.text('Light'));
    expect(Theme.of(_ctx(tester)).brightness, Brightness.light);

    await _tap(tester, find.text('Language'));
    expect(find.textContaining('stays in English'), findsOneWidget);
    await _tap(tester, find.text('Türkçe'));
    expect(session.languageCode, 'tr');
    expect(find.text('Türkçe'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await _tap(tester, find.byType(Switch));
    expect(session.notificationsEnabled, isFalse);

    await _tap(tester, find.text('Privacy Policy'));
    expect(find.textContaining('in memory on this device'), findsOneWidget);
    await _tap(tester, find.text('Close'));
    await _tap(tester, find.text('Support'));
    expect(find.textContaining('Group 39'), findsOneWidget);
    await _tap(tester, find.text('Close'));

    await _tap(tester, find.byType(BackButton));
    expect(find.text('My Groups'), findsOneWidget);
    expect(session.notificationsEnabled, isFalse);
  });

  for (final size in [const Size(320, 568), const Size(430, 932)]) {
    testWidgets(
      'group screens fit ${size.width.toInt()} × ${size.height.toInt()}',
      (tester) async {
        await _openGroups(tester, size: size);
        const keyboard = 270.0;

        await _tap(tester, find.text('Join with invite code'));
        await tester.showKeyboard(find.byType(TextFormField));
        tester.view.viewInsets = const FakeViewPadding(bottom: keyboard);
        await tester.pumpAndSettle();
        final join = _filled('Join Group');
        await tester.ensureVisible(join);
        await tester.pumpAndSettle();
        expect(
          tester.getBottomLeft(join).dy,
          lessThanOrEqualTo(size.height - keyboard),
        );
        tester.view.resetViewInsets();
        await tester.pumpAndSettle();
        await _tap(tester, find.byType(BackButton));

        await _tap(tester, find.text('Interrail Gang'));
        await tester.scrollUntilVisible(
          find.text('TRIPS'),
          120,
          scrollable: find
              .descendant(
                of: find.byType(ListView).last,
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await _tap(tester, find.byType(BackButton));

        Navigator.pushNamed<void>(_ctx(tester), AppRoute.settings);
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Support'));
        expect(tester.takeException(), isNull);
      },
    );
  }
}
