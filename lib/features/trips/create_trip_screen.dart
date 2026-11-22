import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../app/demo_session.dart';
import '../../data/group_store.dart';
import '../../data/trip_store.dart';
import '../../ui/app_theme.dart';
import '../../ui/app_widgets.dart';
import 'trip_format.dart';

/// 05 · Create Trip. Pops with the new trip ID after a confirmed submit.
class CreateTripScreen extends StatefulWidget {
  const CreateTripScreen({super.key});

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _endField = GlobalKey<FormFieldState<String>>();
  var _autovalidate = AutovalidateMode.disabled;
  String? _groupId;
  DateTime? _start;
  DateTime? _end;
  late String _currency;
  String? _coverAsset;
  String? _groupError;
  var _submitting = false;

  @override
  void initState() {
    super.initState();
    _currency = context.read<DemoSession>().defaultCurrencyCode;
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  /// The end date rule depends on the start date. Once errors are showing,
  /// re-check the end date when the start moves so a stale "must be after"
  /// message clears (or a new one appears) without touching the end field.
  void _recheckEnd() {
    if (_autovalidate == AutovalidateMode.disabled) return;
    _endField.currentState?.validate();
  }

  Future<void> _pickCover() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: const Text('Use trip cover'),
              onTap: () => Navigator.pop(sheetContext, AppAssets.tripCover),
            ),
            if (_coverAsset != null)
              ListTile(
                leading: const Icon(Icons.hide_image_outlined),
                title: const Text('Remove cover'),
                onTap: () => Navigator.pop(sheetContext, ''),
              ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;
    setState(() => _coverAsset = choice.isEmpty ? null : choice);
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() {
      _groupError = null;
      _autovalidate = AutovalidateMode.onUserInteraction;
    });
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final groups = context.read<GroupStore>();
    final title = _title.text.trim();
    final groupName = groups.byId(_groupId!)?.name ?? 'your group';
    _submitting = true;
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Create trip?'),
          content: Text(
            'Create “$title” for $groupName, '
            '${TripFormat.dateRange(_start!, _end!)}, in $_currency?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Confirm'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;

      // The group may have been removed while the dialog was open.
      if (groups.byId(_groupId!) == null) {
        setState(() {
          _groupId = null;
          _groupError = 'This group is no longer available. Pick another.';
        });
        _formKey.currentState?.validate();
        return;
      }

      final tripId = context.read<TripStore>().addTrip(
        title: title,
        groupId: _groupId!,
        start: _start!,
        end: _end!,
        currencyCode: _currency,
        coverAsset: _coverAsset,
      );
      if (mounted) Navigator.pop(context, tripId);
    } finally {
      _submitting = false;
    }
  }

  void _openGroups() {
    context.read<DemoSession>().selectTab(AppMainTab.groups);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groups = context.watch<GroupStore>().visibleGroups;
    final today = context.read<TripStore>().demoToday;
    final firstDate = DateTime(today.year - 1);
    final lastDate = DateTime(today.year + 5, 12, 31);
    final currencies = {...TripFormat.currencies, _currency}.toList();
    if (_groupId != null && !groups.any((g) => g.id == _groupId)) {
      _groupId = null;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('New Trip')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: _autovalidate,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.page),
            children: [
              _CoverPicker(asset: _coverAsset, onTap: _pickCover),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                key: const Key('trip-title'),
                controller: _title,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Trip title'),
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? 'Enter a trip title' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              if (groups.isEmpty)
                _NoGroups(onOpenGroups: _openGroups)
              else
                DropdownButtonFormField<String>(
                  // A changed group list rebuilds the field so a removed
                  // group can never stay selected.
                  key: ValueKey(
                    'trip-group:${groups.map((g) => g.id).join(',')}',
                  ),
                  initialValue: _groupId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Travel group'),
                  items: [
                    for (final group in groups)
                      DropdownMenuItem(
                        value: group.id,
                        child: Text(
                          group.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) => setState(() {
                    _groupId = value;
                    _groupError = null;
                  }),
                  validator: (value) =>
                      _groupError ??
                      (value == null ? 'Select a travel group' : null),
                ),
              const SizedBox(height: AppSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TripDateField(
                      key: const Key('trip-start'),
                      label: 'Start date',
                      value: _start,
                      firstDate: firstDate,
                      lastDate: lastDate,
                      initialPickerDate: today,
                      onChanged: (date) {
                        setState(() => _start = date);
                        _recheckEnd();
                      },
                      validator: (value) =>
                          value == null ? 'Select a start date' : null,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TripDateField(
                      key: const Key('trip-end'),
                      fieldKey: _endField,
                      label: 'End date',
                      value: _end,
                      firstDate: firstDate,
                      lastDate: lastDate,
                      initialPickerDate: _start ?? today,
                      onChanged: (date) => setState(() => _end = date),
                      validator: (value) {
                        if (value == null) return 'Select an end date';
                        final start = _start;
                        if (start != null && !value.isAfter(start)) {
                          return 'End date must be after start date';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                key: const Key('trip-currency'),
                initialValue: _currency,
                decoration: const InputDecoration(labelText: 'Currency'),
                items: [
                  for (final code in currencies)
                    DropdownMenuItem(
                      value: code,
                      child: Text('$code (${TripFormat.currencySymbol(code)})'),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _currency = value);
                },
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Your default from Profile. You can change it for this trip.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: groups.isEmpty ? null : _submit,
                child: const Text('Create Trip'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoverPicker extends StatelessWidget {
  const _CoverPicker({required this.asset, required this.onTap});

  final String? asset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = asset;
    return Semantics(
      button: true,
      label: selected == null ? 'Add cover photo' : 'Change cover photo',
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(7),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: AspectRatio(
            aspectRatio: 16 / 7,
            child: selected != null
                ? AppImage(asset: selected)
                : ExcludeSemantics(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Add cover (optional)',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _NoGroups extends StatelessWidget {
  const _NoGroups({required this.onOpenGroups});

  final VoidCallback onOpenGroups;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are not in a travel group yet',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text('Create or join a group first, then plan a trip.'),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: onOpenGroups,
              child: const Text('Go to Groups'),
            ),
          ],
        ),
      ),
    );
  }
}
