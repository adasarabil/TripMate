import 'package:flutter_test/flutter_test.dart';
import 'package:tripmate/data/expense_store.dart';

const _trip = 'interrail-summer';

void main() {
  test('equal split keeps every cent: 100 / 3 → 34, 33, 33', () {
    final shares = ExpenseStore.equalShares(100, ['ada', 'naz', 'ata']);
    expect(shares, {'ada': 34, 'naz': 33, 'ata': 33});
    expect(shares.values.reduce((a, b) => a + b), 100);
  });

  test('seed matches the four wireframe expenses', () {
    final store = ExpenseStore();
    final expenses = store.expensesFor(_trip);
    expect(expenses.map((e) => e.description), [
      'Dinner in Rome',
      'Hostel Florence',
      'Train tickets',
      'Gondola ride',
    ]);
    expect(store.totalSpentMinor(_trip), 59500);
    expect(store.balanceOf(_trip, 'ada'), -2800);
  });

  test('balances always add up to zero', () {
    final store = ExpenseStore();
    store.addExpense(
      tripId: _trip,
      description: 'Pizza',
      amountMinor: 1001,
      paidByUserId: 'arda',
      sharesMinorById: ExpenseStore.equalShares(1001, ['ada', 'naz', 'arda']),
      splitType: SplitType.equal,
    );
    final sum = store
        .balancesFor(_trip)
        .values
        .fold(0, (total, value) => total + value);
    expect(sum, 0);
  });

  test('settlements clear every balance', () {
    final store = ExpenseStore();
    final balances = Map.of(store.balancesFor(_trip));
    for (final transfer in store.settlementsFor(_trip)) {
      expect(transfer.amountMinor, greaterThan(0));
      balances[transfer.fromUserId] =
          balances[transfer.fromUserId]! + transfer.amountMinor;
      balances[transfer.toUserId] =
          balances[transfer.toUserId]! - transfer.amountMinor;
    }
    expect(balances.values.every((value) => value == 0), isTrue);
  });

  test('invalid custom split is rejected and nothing is added', () {
    final store = ExpenseStore();
    var notified = 0;
    store.addListener(() => notified++);
    expect(
      () => store.addExpense(
        tripId: _trip,
        description: 'Hostel',
        amountMinor: 30000,
        paidByUserId: 'ata',
        sharesMinorById: const {'ada': 6000, 'naz': 6000, 'ata': 17000},
        splitType: SplitType.custom,
      ),
      throwsArgumentError,
    );
    expect(store.expensesFor(_trip), hasLength(4));
    expect(notified, 0);
  });

  test('marking a transfer as paid twice changes nothing the second time', () {
    final store = ExpenseStore();
    final transfer = store.settlementsFor(_trip).first;
    var notified = 0;
    store.addListener(() => notified++);
    store.markPaid(_trip, transfer);
    store.markPaid(_trip, transfer);
    expect(store.isPaid(_trip, transfer), isTrue);
    expect(notified, 1);
  });

  test('removing an expense by ID updates list, total and paid marks', () {
    final store = ExpenseStore();
    final transfer = store.settlementsFor(_trip).first;
    store.markPaid(_trip, transfer);
    expect(store.removeExpense('expense-gondola-ride'), isTrue);
    expect(store.removeExpense('expense-gondola-ride'), isFalse);
    expect(
      store.expensesFor(_trip).map((e) => e.id),
      isNot(contains('expense-gondola-ride')),
    );
    expect(store.totalSpentMinor(_trip), 51500);
    expect(store.isPaid(_trip, transfer), isFalse);
  });

  test('former members keep their balance', () {
    final store = ExpenseStore();
    store.addExpense(
      tripId: _trip,
      description: 'Museum',
      amountMinor: 2000,
      paidByUserId: 'someone-who-left',
      sharesMinorById: const {'ada': 1000, 'someone-who-left': 1000},
      splitType: SplitType.equal,
    );
    expect(store.balanceOf(_trip, 'someone-who-left'), 1000);
  });
}
