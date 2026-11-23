import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../app/demo_session.dart';
import '../../app/step22_routes.dart';
import '../../data/demo_models.dart';
import '../../data/expense_store.dart';
import '../../data/group_store.dart';
import '../../data/trip_store.dart';
import '../../ui/app_theme.dart';
import '../trips/trip_format.dart';
import 'expenses_common.dart';

/// 13 · Add Expense for one trip.
class AddExpenseScreen extends StatelessWidget {
  const AddExpenseScreen({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context) {
    final trip = context.read<TripStore>().byId(tripId);
    if (trip == null) {
      return const UnavailableScreen(message: 'This trip could not be found.');
    }
    final group = context.read<GroupStore>().byId(trip.groupId);
    final memberIds = [
      for (final id in group?.memberIds ?? const <String>[])
        if (demoUsers.containsKey(id)) id,
    ];
    return _AddExpenseForm(
      trip: trip,
      memberIds: memberIds,
      currentUserId: context.read<DemoSession>().currentUserId,
    );
  }
}

class _AddExpenseForm extends StatefulWidget {
  const _AddExpenseForm({
    required this.trip,
    required this.memberIds,
    required this.currentUserId,
  });

  final Trip trip;
  final List<String> memberIds;
  final String currentUserId;

  @override
  State<_AddExpenseForm> createState() => _AddExpenseFormState();
}

class _AddExpenseFormState extends State<_AddExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  final _description = TextEditingController();
  final _amount = TextEditingController();
  late final Map<String, TextEditingController> _shares = {
    for (final id in widget.memberIds) id: TextEditingController(),
  };
  late final Set<String> _included = {...widget.memberIds};
  late String? _payer = widget.memberIds.contains(widget.currentUserId)
      ? widget.currentUserId
      : (widget.memberIds.isEmpty ? null : widget.memberIds.first);
  var _split = SplitType.equal;
  var _autovalidate = AutovalidateMode.disabled;
  var _saving = false;

  String get _currency => widget.trip.currencyCode;

  @override
  void dispose() {
    _description.dispose();
    _amount.dispose();
    for (final controller in _shares.values) {
      controller.dispose();
    }
    super.dispose();
  }

  int? get _amountMinor => parseMoneyMinor(_amount.text);

  static String? _moneyError(String text, {required bool allowZero}) {
    final value = text.trim();
    if (value.contains(',')) return 'Use a dot for decimals, e.g. 12.50';
    final minor = parseMoneyMinor(value);
    if (minor == null) return 'Enter a number like 60 or 60.50';
    if (!allowZero && minor <= 0) return 'Amount must be more than 0';
    return null;
  }

  String? _validateAmount(String? text) {
    if ((text ?? '').trim().isEmpty) return 'Please enter an amount';
    return _moneyError(text!, allowZero: false);
  }

  String? _validateShare(String? text) {
    if ((text ?? '').trim().isEmpty) return null; // empty = 0
    return _moneyError(text!, allowZero: true);
  }

  /// Custom shares in minor units, or null while a field is invalid.
  Map<String, int>? get _customShares {
    final shares = <String, int>{};
    for (final entry in _shares.entries) {
      final text = entry.value.text.trim();
      if (text.isEmpty) continue;
      final minor = parseMoneyMinor(text);
      if (minor == null) return null;
      shares[entry.key] = minor;
    }
    return shares;
  }

  Map<String, int> get _equalShares =>
      ExpenseStore.equalShares(_amountMinor ?? 0, [
        for (final id in widget.memberIds)
          if (_included.contains(id)) id,
      ]);

  /// "€0.01 doesn't split evenly: Ada pays one extra cent." — shown in
  /// Equal mode so it is clear who absorbs the rounding.
  String? get _leftoverNote {
    final amount = _amountMinor;
    if (_split != SplitType.equal || amount == null || amount <= 0) {
      return null;
    }
    final payers = ExpenseStore.leftoverCentPayers(amount, [
      for (final id in widget.memberIds)
        if (_included.contains(id)) id,
    ]);
    if (payers.isEmpty) return null;
    final names = [for (final id in payers) memberName(id)];
    final who = names.length == 1
        ? names.single
        : '${names.sublist(0, names.length - 1).join(', ')} and ${names.last}';
    final verb = names.length == 1 ? 'pays' : 'each pay';
    return '${ExpenseFormat.money(payers.length, _currency)} doesn\'t split '
        'evenly: $who $verb one extra cent.';
  }

  /// The error shown under the member list, if any.
  String? get _splitError {
    if (_autovalidate == AutovalidateMode.disabled) return null;
    final amount = _amountMinor;
    if (_split == SplitType.equal) {
      return _included.isEmpty ? 'Select at least one member' : null;
    }
    final shares = _customShares;
    if (shares == null || amount == null || amount <= 0) return null;
    final sum = shares.values.fold(0, (total, share) => total + share);
    if (sum == amount) return null;
    return 'Shares add up to ${ExpenseFormat.money(sum, _currency)} — '
        'must equal ${ExpenseFormat.money(amount, _currency)}';
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
    final fieldsValid = _formKey.currentState!.validate();
    if (!fieldsValid || _splitError != null) return;

    final amount = _amountMinor!;
    final shares = _split == SplitType.equal ? _equalShares : _customShares!;
    final description = _description.text.trim();
    final confirmed = await confirmTripAction(
      context,
      title: 'Save expense?',
      message:
          'Add “$description” for ${ExpenseFormat.money(amount, _currency)}, '
          'paid by ${memberName(_payer!)}?',
      confirmLabel: 'Save',
    );
    if (!confirmed || !mounted || _saving) return;
    _saving = true;
    context.read<ExpenseStore>().addExpense(
      tripId: widget.trip.id,
      description: description,
      amountMinor: amount,
      paidByUserId: _payer!,
      sharesMinorById: shares,
      splitType: _split,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final symbol = TripFormat.currencySymbol(_currency).trim();
    final noMembers = widget.memberIds.isEmpty;
    final splitError = _splitError;

    return Scaffold(
      appBar: AppBar(title: const Text('Add Expense')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: _autovalidate,
          onChanged: () => setState(() {}),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.lg,
              AppSpacing.page,
              AppSpacing.xxl,
            ),
            children: [
              TextFormField(
                key: const Key('expense-description'),
                controller: _description,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Hostel Florence',
                ),
                validator: (text) => (text ?? '').trim().isEmpty
                    ? 'Please enter a description'
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      key: const Key('expense-amount'),
                      controller: _amount,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Amount ($symbol)',
                        hintText: '300.00',
                      ),
                      validator: _validateAmount,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      key: const Key('expense-payer'),
                      initialValue: _payer,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Paid by'),
                      items: [
                        for (final id in widget.memberIds)
                          DropdownMenuItem(
                            value: id,
                            child: Text(
                              memberName(id),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: noMembers
                          ? null
                          : (id) => setState(() => _payer = id),
                      validator: (id) => id == null ? 'Choose who paid' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Split', style: theme.textTheme.bodySmall),
              const SizedBox(height: AppSpacing.xs),
              SegmentedButton<SplitType>(
                showSelectedIcon: false,
                expandedInsets: EdgeInsets.zero,
                segments: const [
                  ButtonSegment(value: SplitType.equal, label: Text('Equal')),
                  ButtonSegment(value: SplitType.custom, label: Text('Custom')),
                ],
                selected: {_split},
                onSelectionChanged: (selection) =>
                    setState(() => _split = selection.first),
              ),
              const SizedBox(height: AppSpacing.md),
              if (noMembers)
                Text(
                  'This trip has no group members to split with. '
                  'Add members to the trip group first.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              else
                for (final id in widget.memberIds) _memberRow(context, id),
              if (_leftoverNote case final note?)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    note,
                    key: const Key('expense-leftover-note'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              if (splitError != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    splitError,
                    key: const Key('expense-split-error'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: noMembers ? null : _save,
                child: const Text('Save Expense'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _memberRow(BuildContext context, String id) {
    final theme = Theme.of(context);
    final name = Text(memberName(id), overflow: TextOverflow.ellipsis);
    if (_split == SplitType.equal) {
      final share = _equalShares[id];
      return CheckboxListTile(
        key: Key('expense-include-$id'),
        contentPadding: EdgeInsets.zero,
        dense: true,
        value: _included.contains(id),
        onChanged: (checked) => setState(() {
          if (checked == true) {
            _included.add(id);
          } else {
            _included.remove(id);
          }
        }),
        secondary: MemberAvatar(id),
        title: Row(
          children: [
            Expanded(child: name),
            if (share != null && (_amountMinor ?? 0) > 0)
              Text(
                ExpenseFormat.money(share, _currency),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      );
    }
    final hasSumError = _splitError != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: MemberAvatar(id),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: name,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 110,
            child: Semantics(
              label: 'Share of ${memberName(id)}',
              child: TextFormField(
                key: Key('expense-share-$id'),
                controller: _shares[id],
                textAlign: TextAlign.end,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  hintText: '0.00',
                  enabledBorder: hasSumError
                      ? OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                          borderSide: BorderSide(
                            color: theme.colorScheme.error,
                          ),
                        )
                      : null,
                ),
                validator: _validateShare,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
