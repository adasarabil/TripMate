import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../app/step22_routes.dart';
import '../../data/demo_models.dart';
import '../../data/group_store.dart';
import '../../data/trip_store.dart';
import '../../ui/app_theme.dart';
import 'groups_common.dart';

/// 18 · My Groups, the Groups root tab.
class MyGroupsScreen extends StatefulWidget {
  const MyGroupsScreen({super.key});

  @override
  State<MyGroupsScreen> createState() => _MyGroupsScreenState();
}

class _MyGroupsScreenState extends State<MyGroupsScreen> {
  var _busy = false;

  Future<void> _guard(Future<void> Function() action) async {
    if (_busy) return;
    _busy = true;
    try {
      await action();
    } finally {
      _busy = false;
    }
  }

  void _openDetail(String groupId) => Navigator.pushNamed<void>(
    context,
    AppRoute.groupDetail,
    arguments: groupId,
  );

  Future<void> _createGroup() => _guard(() async {
    final groupId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const CreateGroupSheet(),
    );
    if (groupId != null && mounted) _openDetail(groupId);
  });

  Future<void> _joinGroup() => _guard(() async {
    final groupId = await Navigator.pushNamed<String>(
      context,
      AppRoute.joinGroup,
    );
    if (groupId != null && mounted) _openDetail(groupId);
  });

  Future<void> _leave(Group group) => _guard(() async {
    if (!await confirmLeaveGroup(context, group) || !mounted) return;
    context.read<GroupStore>().leaveGroup(group.id);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('You left ${group.name}.')));
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groups = context.watch<GroupStore>().visibleGroups;
    final trips = context.watch<TripStore>().trips;

    return Scaffold(
      appBar: AppBar(title: const Text('My Groups')),
      body: ListView(
        key: const PageStorageKey('my-groups-list'),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.lg,
          AppSpacing.page,
          88,
        ),
        children: [
          if (groups.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Text(
                'You are not in any group yet. Create one or join with an '
                'invite code.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          for (final group in groups)
            _GroupCard(
              key: ValueKey(group.id),
              group: group,
              tripCount: trips.where((t) => t.groupId == group.id).length,
              onOpen: () => _openDetail(group.id),
              onLeave: () => _leave(group),
            ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: _joinGroup,
            icon: const Icon(Icons.vpn_key_outlined, size: 18),
            label: const Text('Join with invite code'),
          ),
        ],
      ),
      floatingActionButton: SizedBox.square(
        dimension: 48,
        child: FloatingActionButton(
          tooltip: 'Create Group',
          onPressed: _createGroup,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    super.key,
    required this.group,
    required this.tripCount,
    required this.onOpen,
    required this.onLeave,
  });

  final Group group;
  final int tripCount;
  final VoidCallback onOpen;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: onOpen,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      InitialThumb(group.name),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              group.name,
                              style: theme.textTheme.titleSmall,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${memberLabel(group.memberIds.length)} · '
                              '${tripLabel(tripCount)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Leave ${group.name}',
              onPressed: onLeave,
              icon: const Icon(Icons.close, size: 16),
            ),
          ],
        ),
      ),
    );
  }
}

/// Create Group bottom sheet. Pops with the new group ID when saved.
class CreateGroupSheet extends StatefulWidget {
  const CreateGroupSheet({super.key});

  @override
  State<CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends State<CreateGroupSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  var _saved = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    if (_saved || !(_formKey.currentState?.validate() ?? false)) return;
    _saved = true;
    final id = context.read<GroupStore>().createGroup(_name.text);
    Navigator.pop(context, id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.page,
        0,
        AppSpacing.page,
        AppSpacing.page + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Create Group', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'You will be the owner. An invite code is created for you.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _name,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(labelText: 'Group name'),
              validator: (value) =>
                  (value ?? '').trim().isEmpty ? 'Enter a group name' : null,
              onFieldSubmitted: (_) => _save(),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(onPressed: _save, child: const Text('Create Group')),
          ],
        ),
      ),
    );
  }
}
