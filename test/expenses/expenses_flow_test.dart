import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:tripmate/app/demo_session.dart';
import 'package:tripmate/data/expense_store.dart';
import 'package:tripmate/main.dart';

Finder _filled(String label) => find.widgetWithText(FilledButton, label);

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

/// Taps a floating action button. Its tab lives inside the trip's
/// TabBarView, so ensureVisible would scroll the pages sideways first.
Future<void> _tapFab(WidgetTester tester, String tooltip) async {
  await tester.tap(find.byTooltip(tooltip));
  await tester.pumpAndSettle();
}

Future<void> _enter(WidgetTester tester, String key, String text) async {
  final field = find.byKey(Key(key));
  await tester.ensureVisible(field);
  await tester.enterText(field, text);
  await tester.pumpAndSettle();
}

Future<void> _logIn(
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
}

Future<void> _openExpenses(WidgetTester tester, {Size? size}) async {
  await _logIn(tester, size: size ?? const Size(390, 780));
  await _tap(tester, find.text('Interrail Summer'));
  await _tap(tester, find.text('Expenses'));
}

void main() {
  testWidgets('expenses tab shows totals derived from the store', (
    tester,
  ) async {
    await _openExpenses(tester);
    expect(find.text('€595.00'), findsOneWidget);
    expect(find.text('−€28.00'), findsOneWidget);
    expect(find.text('Dinner in Rome'), findsOneWidget);
    expect(find.text('Paid by Naz · split equally (5)'), findsOneWidget);
    expect(find.text('Paid by Ata · custom split'), findsOneWidget);
  });

  testWidgets('custom split must add up before the expense is saved', (
    tester,
  ) async {
    await _openExpenses(tester);
    await _tapFab(tester, 'Add expense');
    await _enter(tester, 'expense-description', 'Bike rental');
    await _enter(tester, 'expense-amount', '300');
    await _tap(tester, find.text('Custom'));
    const shares = {
      'ada': '60',
      'naz': '60',
      'ata': '80',
      'emre': '60',
      'arda': '30',
    };
    for (final entry in shares.entries) {
      await _enter(tester, 'expense-share-${entry.key}', entry.value);
    }
    await _tap(tester, _filled('Save Expense'));
    expect(
      find.text('Shares add up to €290.00 — must equal €300.00'),
      findsOneWidget,
    );
    expect(find.text('Save expense?'), findsNothing);

    await _enter(tester, 'expense-share-arda', '40');
    expect(find.byKey(const Key('expense-split-error')), findsNothing);
    await _tap(tester, _filled('Save Expense'));
    expect(find.text('Save expense?'), findsOneWidget);
    await _tap(tester, _filled('Save'));

    expect(find.text('Bike rental'), findsOneWidget);
    expect(find.text('€895.00'), findsOneWidget);
    final context = tester.element(find.text('Bike rental'));
    expect(
      context.read<ExpenseStore>().expensesFor('interrail-summer'),
      hasLength(5),
    );
  });

  testWidgets('cancel in the confirmation dialog saves nothing', (
    tester,
  ) async {
    await _openExpenses(tester);
    await _tapFab(tester, 'Add expense');
    await _tap(tester, _filled('Save Expense'));
    expect(find.text('Please enter a description'), findsOneWidget);
    expect(find.text('Please enter an amount'), findsOneWidget);

    await _enter(tester, 'expense-description', 'Snacks');
    await _enter(tester, 'expense-amount', '10');
    await _tap(tester, _filled('Save Expense'));
    await _tap(tester, find.text('Cancel'));
    expect(find.text('Add Expense'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Snacks'), findsNothing);
    expect(find.text('€595.00'), findsOneWidget);
  });

  testWidgets('removing an expense updates the list and the total', (
    tester,
  ) async {
    await _openExpenses(tester);
    await _tap(tester, find.byTooltip('Remove Gondola ride'));
    await _tap(tester, find.text('Cancel'));
    expect(find.text('Gondola ride'), findsOneWidget);

    await _tap(tester, find.byTooltip('Remove Gondola ride'));
    await _tap(tester, _filled('Remove'));
    expect(find.text('Gondola ride'), findsNothing);
    expect(find.text('Dinner in Rome'), findsOneWidget);
    expect(find.text('€515.00'), findsOneWidget);
  });

  testWidgets('settle up lists transfers and marks one as paid once', (
    tester,
  ) async {
    await _openExpenses(tester);
    await _tap(tester, _filled('Settle up'));
    expect(find.text('WHO OWES WHOM'), findsOneWidget);
    expect(find.text('Arda → Ata'), findsOneWidget);
    expect(find.text('€83.00'), findsOneWidget);
    expect(find.text('+€157.00'), findsOneWidget);

    final paidButtons = find.widgetWithText(OutlinedButton, 'Paid');
    final before = tester.widgetList(paidButtons).length;
    await _tap(tester, paidButtons.first);
    expect(tester.widgetList(paidButtons).length, before - 1);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    expect(find.text('+€157.00'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await _tap(tester, _filled('Settle up'));
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
  });

  testWidgets('profile changes the default currency and logs out', (
    tester,
  ) async {
    await _logIn(tester);
    await _tap(tester, find.text('Profile'));
    expect(find.text('Ada Derviş Sarabil'), findsOneWidget);
    expect(find.text('@adasarabil · ada@example.com'), findsOneWidget);
    expect(find.text('trips'), findsOneWidget);

    await _tap(tester, find.byKey(const Key('profile-currency')));
    await _tap(tester, find.text('USD').last);
    final context = tester.element(find.text('Ada Derviş Sarabil'));
    final session = context.read<DemoSession>();
    expect(session.defaultCurrencyCode, 'USD');

    await _tap(tester, find.byTooltip('Settings'));
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Ada Derviş Sarabil'), findsOneWidget);

    await _tap(tester, find.widgetWithText(OutlinedButton, 'Log Out'));
    expect(find.text('TripMate'), findsOneWidget);
    expect(session.currentTab, AppMainTab.trips);
  });

  testWidgets('add expense form fits a small phone', (tester) async {
    await _openExpenses(tester, size: const Size(320, 568));
    await _tapFab(tester, 'Add expense');
    await _tap(tester, find.text('Custom'));
    await _tap(tester, _filled('Save Expense'));
    expect(tester.takeException(), isNull);
  });
}
