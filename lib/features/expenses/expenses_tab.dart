import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../app/demo_session.dart';
import '../../app/step22_routes.dart';
import '../../data/expense_store.dart';
import '../../data/trip_store.dart';
import '../../ui/app_theme.dart';
import '../trips/trip_format.dart';
import 'expenses_common.dart';

/// 12 · Trip Detail – Expenses tab body.
class ExpensesTab extends StatelessWidget {
  const ExpensesTab({super.key, required this.tripId});

  final String tripId;

  Future<void> _remove(BuildContext context, Expense expense) async {
    final confirmed = await confirmTripAction(
      context,
      title: 'Remove expense?',
      message: 'Remove “${expense.description}” from this trip?',
      confirmLabel: 'Remove',
    );
    if (!confirmed || !context.mounted) return;
    context.read<ExpenseStore>().removeExpense(expense.id);
  }

  @override
  Widget build(BuildContext context) {
    final trip = context.select((TripStore store) => store.byId(tripId));
    if (trip == null) {
      return const Center(child: Text('This trip could not be found.'));
    }
    final userId = context.select((DemoSession s) => s.currentUserId);
    final store = context.watch<ExpenseStore>();
    final expenses = store.expensesFor(tripId);
    final currency = trip.currencyCode;
    final theme = Theme.of(context);

    return Scaffold(
      body: ListView(
        key: PageStorageKey('expenses-$tripId'),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.lg,
          AppSpacing.page,
          96,
        ),
        children: [
          _SummaryCard(
            total: ExpenseFormat.money(store.totalSpentMinor(tripId), currency),
            balance: ExpenseFormat.signedMoney(
              store.balanceOf(tripId, userId),
              currency,
            ),
            onSettleUp: () => Navigator.pushNamed<void>(
              context,
              AppRoute.settleUp,
              arguments: tripId,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const ExpenseSectionLabel('EXPENSES'),
          const SizedBox(height: AppSpacing.sm),
          if (expenses.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Text(
                'No expenses yet. Add one with +.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            for (final expense in expenses)
              Padding(
                key: ValueKey(expense.id),
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _ExpenseCard(
                  expense: expense,
                  currencyCode: currency,
                  onRemove: () => _remove(context, expense),
                ),
              ),
        ],
      ),
      floatingActionButton: SizedBox.square(
        dimension: 48,
        child: FloatingActionButton(
          heroTag: 'expenses-fab',
          tooltip: 'Add expense',
          onPressed: () => Navigator.pushNamed<void>(
            context,
            AppRoute.addExpense,
            arguments: tripId,
          ),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.total,
    required this.balance,
    required this.onSettleUp,
  });

  final String total;
  final String balance;
  final VoidCallback onSettleUp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total spent', style: muted),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          total,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Your balance', style: muted),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          balance,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: onSettleUp,
              style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
              child: const Text('Settle up'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  const _ExpenseCard({
    required this.expense,
    required this.currencyCode,
    required this.onRemove,
  });

  final Expense expense;
  final String currencyCode;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final split = switch (expense.splitType) {
      SplitType.equal => 'split equally (${expense.sharesMinorById.length})',
      SplitType.custom => 'custom split',
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.xs,
          AppSpacing.sm,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Paid by ${memberName(expense.paidByUserId)} · $split',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 110),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  TripFormat.money(expense.amountMinor, currencyCode),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Remove ${expense.description}',
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
