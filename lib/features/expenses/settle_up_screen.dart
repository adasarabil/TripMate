import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../app/step22_routes.dart';
import '../../data/expense_store.dart';
import '../../data/group_store.dart';
import '../../data/trip_store.dart';
import '../../ui/app_theme.dart';
import 'expenses_common.dart';

/// 14 · Settle Up: the fewest "X pays Y" transfers and each net balance.
class SettleUpScreen extends StatelessWidget {
  const SettleUpScreen({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context) {
    final trip = context.select((TripStore store) => store.byId(tripId));
    if (trip == null) {
      return const UnavailableScreen(message: 'This trip could not be found.');
    }
    final group = context.read<GroupStore>().byId(trip.groupId);
    final store = context.watch<ExpenseStore>();
    final transfers = store.settlementsFor(tripId);
    final balances =
        store
            .balancesFor(tripId, memberIds: group?.memberIds ?? const [])
            .entries
            .toList()
          ..sort((a, b) {
            final byValue = b.value.compareTo(a.value);
            return byValue != 0 ? byValue : a.key.compareTo(b.key);
          });
    final allPaid =
        transfers.isNotEmpty && transfers.every((t) => store.isPaid(tripId, t));
    final currency = trip.currencyCode;
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Settle Up')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.lg,
            AppSpacing.page,
            AppSpacing.xxl,
          ),
          children: [
            Text(
              'Fewest transfers to settle all expenses of this trip.',
              style: muted,
            ),
            const SizedBox(height: AppSpacing.md),
            const ExpenseSectionLabel('WHO OWES WHOM'),
            const SizedBox(height: AppSpacing.sm),
            if (transfers.isEmpty)
              Text(
                balances.isEmpty
                    ? 'No expenses yet, so nobody owes anything.'
                    : 'Everyone is settled up.',
                style: muted,
              )
            else ...[
              for (final transfer in transfers)
                Padding(
                  key: ValueKey(transfer.key),
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _TransferCard(
                    transfer: transfer,
                    currencyCode: currency,
                    paid: store.isPaid(tripId, transfer),
                    onPaid: () => store.markPaid(tripId, transfer),
                  ),
                ),
              if (allPaid)
                Text('All transfers are marked as paid.', style: muted),
            ],
            const SizedBox(height: AppSpacing.lg),
            const ExpenseSectionLabel('BALANCES'),
            const SizedBox(height: AppSpacing.sm),
            for (final entry in balances)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        memberName(entry.key),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      ExpenseFormat.signedMoney(entry.value, currency),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            if (transfers.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                'Balances show the original split. Marking a transfer as '
                'paid does not change them.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TransferCard extends StatelessWidget {
  const _TransferCard({
    required this.transfer,
    required this.currencyCode,
    required this.paid,
    required this.onPaid,
  });

  final Settlement transfer;
  final String currencyCode;
  final bool paid;
  final VoidCallback onPaid;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final from = memberName(transfer.fromUserId);
    final to = memberName(transfer.toUserId);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            MemberAvatar(transfer.fromUserId),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                '$from → $to',
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  decoration: paid ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              ExpenseFormat.money(transfer.amountMinor, currencyCode),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            if (paid)
              Semantics(
                label: '$from paid $to',
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  child: Icon(Icons.check_circle_outline, size: 22),
                ),
              )
            else
              OutlinedButton(
                onPressed: onPaid,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                ),
                child: Text('Paid', semanticsLabel: 'Mark $from → $to as paid'),
              ),
          ],
        ),
      ),
    );
  }
}
