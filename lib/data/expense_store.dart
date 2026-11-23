import 'package:flutter/foundation.dart';

enum SplitType { equal, custom }

/// One shared expense of a trip. Money is always kept in minor units
/// (cents) so splits never lose a cent to rounding.
class Expense {
  Expense({
    required this.id,
    required this.tripId,
    required this.description,
    required this.amountMinor,
    required this.paidByUserId,
    required Map<String, int> sharesMinorById,
    required this.splitType,
  }) : sharesMinorById = Map.unmodifiable(sharesMinorById);

  final String id;
  final String tripId;
  final String description;
  final int amountMinor;
  final String paidByUserId;

  /// Member ID → that member's share. Shares always add up to [amountMinor].
  final Map<String, int> sharesMinorById;
  final SplitType splitType;
}

/// "[fromUserId] pays [toUserId] [amountMinor]" to settle up.
class Settlement {
  const Settlement({
    required this.fromUserId,
    required this.toUserId,
    required this.amountMinor,
  });

  final String fromUserId;
  final String toUserId;
  final int amountMinor;

  /// Stable key used to remember that this transfer was marked as paid.
  String get key => '$fromUserId>$toUserId:$amountMinor';
}

class ExpenseStore extends ChangeNotifier {
  final List<Expense> _expenses = [..._seed];

  /// Trip ID → keys of transfers marked as paid. Cleared for a trip whenever
  /// its expense list changes, because the transfers are recalculated then.
  final Map<String, Set<String>> _paidByTrip = {};
  var _nextId = 1;

  List<Expense> expensesFor(String tripId) =>
      List.unmodifiable(_expenses.where((expense) => expense.tripId == tripId));

  int totalSpentMinor(String tripId) =>
      expensesFor(tripId).fold(0, (sum, expense) => sum + expense.amountMinor);

  /// Net balance per member: what they paid minus their shares.
  /// Positive = others owe them, negative = they owe. The values add up to 0.
  /// [memberIds] are listed even with a zero balance.
  Map<String, int> balancesFor(
    String tripId, {
    Iterable<String> memberIds = const [],
  }) {
    final balances = <String, int>{for (final id in memberIds) id: 0};
    for (final expense in expensesFor(tripId)) {
      balances.update(
        expense.paidByUserId,
        (value) => value + expense.amountMinor,
        ifAbsent: () => expense.amountMinor,
      );
      expense.sharesMinorById.forEach((id, share) {
        balances.update(id, (value) => value - share, ifAbsent: () => -share);
      });
    }
    return balances;
  }

  int balanceOf(String tripId, String userId) =>
      balancesFor(tripId)[userId] ?? 0;

  /// A short list of transfers that settles every balance: the largest
  /// debtor always pays the largest creditor; ties are broken by member ID.
  List<Settlement> settlementsFor(String tripId) {
    final balances = balancesFor(tripId);
    final debtors = [
      for (final entry in balances.entries)
        if (entry.value < 0) _Open(entry.key, -entry.value),
    ];
    final creditors = [
      for (final entry in balances.entries)
        if (entry.value > 0) _Open(entry.key, entry.value),
    ];
    final transfers = <Settlement>[];
    while (debtors.isNotEmpty && creditors.isNotEmpty) {
      debtors.sort(_Open.largestFirst);
      creditors.sort(_Open.largestFirst);
      final debtor = debtors.first;
      final creditor = creditors.first;
      final amount = debtor.amount < creditor.amount
          ? debtor.amount
          : creditor.amount;
      transfers.add(
        Settlement(
          fromUserId: debtor.id,
          toUserId: creditor.id,
          amountMinor: amount,
        ),
      );
      debtor.amount -= amount;
      creditor.amount -= amount;
      if (debtor.amount == 0) debtors.removeAt(0);
      if (creditor.amount == 0) creditors.removeAt(0);
    }
    return transfers;
  }

  bool isPaid(String tripId, Settlement transfer) =>
      _paidByTrip[tripId]?.contains(transfer.key) ?? false;

  /// Marks [transfer] as paid. Doing it twice changes nothing.
  void markPaid(String tripId, Settlement transfer) {
    final paid = _paidByTrip.putIfAbsent(tripId, () => <String>{});
    if (paid.add(transfer.key)) notifyListeners();
  }

  /// Adds one expense and returns its new ID.
  /// Throws [ArgumentError] when the data is invalid; nothing is added then.
  String addExpense({
    required String tripId,
    required String description,
    required int amountMinor,
    required String paidByUserId,
    required Map<String, int> sharesMinorById,
    required SplitType splitType,
  }) {
    final text = description.trim();
    if (text.isEmpty) {
      throw ArgumentError.value(description, 'description', 'is empty');
    }
    if (amountMinor <= 0) {
      throw ArgumentError.value(amountMinor, 'amountMinor', 'must be > 0');
    }
    if (paidByUserId.isEmpty) {
      throw ArgumentError.value(paidByUserId, 'paidByUserId', 'is empty');
    }
    final shares = {
      for (final entry in sharesMinorById.entries)
        if (entry.value != 0) entry.key: entry.value,
    };
    if (shares.isEmpty || shares.values.any((share) => share < 0)) {
      throw ArgumentError.value(sharesMinorById, 'sharesMinorById');
    }
    final sum = shares.values.fold(0, (total, share) => total + share);
    if (sum != amountMinor) {
      throw ArgumentError.value(
        sharesMinorById,
        'sharesMinorById',
        'add up to $sum, not $amountMinor',
      );
    }

    String id;
    do {
      id = 'expense-${_nextId++}';
    } while (_expenses.any((expense) => expense.id == id));
    _expenses.add(
      Expense(
        id: id,
        tripId: tripId,
        description: text,
        amountMinor: amountMinor,
        paidByUserId: paidByUserId,
        sharesMinorById: shares,
        splitType: splitType,
      ),
    );
    _paidByTrip.remove(tripId);
    notifyListeners();
    return id;
  }

  /// Removes the expense with [id]. Returns false when it does not exist.
  bool removeExpense(String id) {
    final index = _expenses.indexWhere((expense) => expense.id == id);
    if (index < 0) return false;
    final removed = _expenses.removeAt(index);
    _paidByTrip.remove(removed.tripId);
    notifyListeners();
    return true;
  }

  /// Splits [amountMinor] equally between [memberIds]. Leftover cents go to
  /// the first members in the given order, e.g. 100 / 3 → 34, 33, 33.
  static Map<String, int> equalShares(int amountMinor, List<String> memberIds) {
    if (memberIds.isEmpty) return const {};
    final base = amountMinor ~/ memberIds.length;
    final rest = amountMinor - base * memberIds.length;
    return {
      for (var i = 0; i < memberIds.length; i++)
        memberIds[i]: base + (i < rest ? 1 : 0),
    };
  }

  /// Members who pay one extra cent when [amountMinor] does not split
  /// evenly between [memberIds], in the same order [equalShares] uses.
  /// 100 / 3 → ['ada'] (the 1 leftover cent goes to the first member).
  static List<String> leftoverCentPayers(
    int amountMinor,
    List<String> memberIds,
  ) {
    if (memberIds.isEmpty || amountMinor <= 0) return const [];
    final rest = amountMinor % memberIds.length;
    return List.unmodifiable(memberIds.take(rest));
  }

  static final _seed = <Expense>[
    Expense(
      id: 'expense-dinner-rome',
      tripId: 'interrail-summer',
      description: 'Dinner in Rome',
      amountMinor: 12000,
      paidByUserId: 'naz',
      sharesMinorById: equalShares(12000, _interrail),
      splitType: SplitType.equal,
    ),
    Expense(
      id: 'expense-hostel-florence',
      tripId: 'interrail-summer',
      description: 'Hostel Florence',
      amountMinor: 30000,
      paidByUserId: 'ata',
      sharesMinorById: const {
        'ada': 6000,
        'naz': 6000,
        'ata': 8000,
        'emre': 6000,
        'arda': 4000,
      },
      splitType: SplitType.custom,
    ),
    Expense(
      id: 'expense-train-tickets',
      tripId: 'interrail-summer',
      description: 'Train tickets',
      amountMinor: 9500,
      paidByUserId: 'ada',
      sharesMinorById: equalShares(9500, _interrail),
      splitType: SplitType.equal,
    ),
    Expense(
      id: 'expense-gondola-ride',
      tripId: 'interrail-summer',
      description: 'Gondola ride',
      amountMinor: 8000,
      paidByUserId: 'emre',
      sharesMinorById: equalShares(8000, const ['ada', 'naz', 'ata', 'emre']),
      splitType: SplitType.equal,
    ),
  ];

  static const _interrail = ['ada', 'naz', 'ata', 'emre', 'arda'];
}

class _Open {
  _Open(this.id, this.amount);

  final String id;
  int amount;

  static int largestFirst(_Open a, _Open b) {
    final byAmount = b.amount.compareTo(a.amount);
    return byAmount != 0 ? byAmount : a.id.compareTo(b.id);
  }
}
