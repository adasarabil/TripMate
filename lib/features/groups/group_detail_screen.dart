import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/demo_session.dart';
import '../../app/step22_routes.dart';
import '../../data/demo_models.dart';
import '../../data/group_store.dart';
import '../../data/trip_store.dart';
import '../../ui/app_theme.dart';
import '../trips/trip_format.dart';
import 'groups_common.dart';

/// 19 · Group Detail & Invite.
class GroupDetailScreen extends StatefulWidget {
  const GroupDetailScreen({super.key, required this.groupId});

  final String groupId;

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  final _username = TextEditingController();
  String? _inviteError;
  var _busy = false;

  @override
  void dispose() {
    _username.dispose();
    super.dispose();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _guard(Future<void> Function() action) async {
    if (_busy) return;
    _busy = true;
    try {
      await action();
    } finally {
      _busy = false;
    }
  }

  Future<void> _copy(Group group) async {
    await Clipboard.setData(ClipboardData(text: group.inviteCode));
    if (mounted) _snack('Invite code ${group.inviteCode} copied.');
  }

  String _shareText(Group group) =>
      'Join “${group.name}” on TripMate with invite code ${group.inviteCode}.';

  Future<void> _share(Group group) => _guard(() async {
    final box = context.findRenderObject() as RenderBox?;
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: _shareText(group),
          subject: 'TripMate invite',
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (_) {
      // No native share sheet (e.g. tests or an unsupported platform).
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) => _InAppShareSheet(
          text: _shareText(group),
          onCopy: () async {
            Navigator.pop(sheetContext);
            await _copy(group);
          },
        ),
      );
    }
  });

  void _invite(Group group) {
    final store = context.read<GroupStore>();
    final result = store.inviteByUsername(group.id, _username.text);
    final username = GroupStore.normalizeUsername(_username.text);
    setState(() {
      _inviteError = switch (result) {
        InviteResult.added => null,
        InviteResult.empty => 'Enter a username',
        InviteResult.unknownUser => 'No user found with @$username',
        InviteResult.alreadyMember => '@$username is already a member',
        InviteResult.unknownGroup => 'This group is no longer available',
      };
    });
    if (result == InviteResult.added) {
      _username.clear();
      FocusScope.of(context).unfocus();
      _snack('@$username was added to ${group.name}.');
    }
  }

  Future<void> _removeMember(Group group, DemoUser user) => _guard(() async {
    final confirmed = await confirmAction(
      context,
      title: 'Remove member?',
      message:
          'Remove ${user.displayName} from ${group.name}? Past expenses '
          'keep their name.',
      confirmLabel: 'Remove',
    );
    if (!confirmed || !mounted) return;
    context.read<GroupStore>().removeMember(group.id, user.id);
  });

  Future<void> _removeTrip(Trip trip) => _guard(() async {
    final confirmed = await confirmAction(
      context,
      title: 'Remove trip?',
      message: 'Remove “${trip.title}”? It is also removed from My Trips.',
    );
    if (!confirmed || !mounted) return;
    context.read<TripStore>().removeTrip(trip.id);
  });

  Future<void> _leave(Group group) => _guard(() async {
    if (!await confirmLeaveGroup(context, group) || !mounted) return;
    context.read<GroupStore>().leaveGroup(group.id);
    Navigator.pop(context);
  });

  @override
  Widget build(BuildContext context) {
    final store = context.watch<GroupStore>();
    final group = store.byId(widget.groupId);
    if (group == null || !store.isVisible(group.id)) {
      return _UnavailableGroup(name: group?.name);
    }

    final theme = Theme.of(context);
    final userId = context.select((DemoSession s) => s.currentUserId);
    final isOwner = group.ownerId == userId;
    final trips = context
        .watch<TripStore>()
        .trips
        .where((trip) => trip.groupId == group.id)
        .toList();
    final section = theme.textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w700,
    );
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(group.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Group options',
            icon: const Icon(Icons.more_vert),
            onSelected: (_) => _leave(group),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'leave', child: Text('Leave group')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.lg,
            AppSpacing.page,
            AppSpacing.xxl,
          ),
          children: [
            Text('Invite code', style: section),
            const SizedBox(height: AppSpacing.sm),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    SelectableText(
                      group.inviteCode,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _copy(group),
                          icon: const Icon(Icons.copy, size: 16),
                          label: const Text('Copy'),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        FilledButton.icon(
                          onPressed: () => _share(group),
                          icon: const Icon(Icons.share, size: 16),
                          label: const Text('Share'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Invite by username', style: section),
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _username,
                    autocorrect: false,
                    textInputAction: TextInputAction.send,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      hintText: '@username',
                      errorText: _inviteError,
                    ),
                    onChanged: (_) {
                      if (_inviteError != null) {
                        setState(() => _inviteError = null);
                      }
                    },
                    onSubmitted: (_) => _invite(group),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                FilledButton(
                  onPressed: () => _invite(group),
                  child: const Text('Invite'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('MEMBERS (${group.memberIds.length})', style: section),
            const SizedBox(height: AppSpacing.sm),
            for (final id in group.memberIds)
              _MemberRow(
                key: ValueKey('member-$id'),
                userId: id,
                isOwner: id == group.ownerId,
                isYou: id == userId,
                onRemove: isOwner && id != group.ownerId
                    ? (user) => _removeMember(group, user)
                    : null,
              ),
            const SizedBox(height: AppSpacing.xl),
            Text('TRIPS', style: section),
            const SizedBox(height: AppSpacing.sm),
            if (trips.isEmpty)
              Text('No trips for this group yet.', style: muted),
            for (final trip in trips)
              Padding(
                key: ValueKey('trip-${trip.id}'),
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => Navigator.pushNamed<void>(
                            context,
                            AppRoute.tripDetail,
                            arguments: trip.id,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  trip.title,
                                  style: theme.textTheme.titleSmall,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  TripFormat.dateRange(trip.start, trip.end),
                                  style: muted,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Remove ${trip.title}',
                        onPressed: () => _removeTrip(trip),
                        icon: const Icon(Icons.close, size: 16),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    super.key,
    required this.userId,
    required this.isOwner,
    required this.isYou,
    required this.onRemove,
  });

  final String userId;
  final bool isOwner;
  final bool isYou;
  final ValueChanged<DemoUser>? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = demoUsers[userId];
    final name = user?.displayName ?? userId;
    final tags = [if (isOwner) 'Owner', if (isYou) 'You'].join(' · ');
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            foregroundColor: theme.colorScheme.onSurface,
            child: Text(name.characters.first.toUpperCase()),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tags.isEmpty ? name : '$name · $tags',
                  style: theme.textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (user != null)
                  Text(
                    '@${user.username}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          if (onRemove != null && user != null)
            IconButton(
              tooltip: 'Remove $name',
              onPressed: () => onRemove!(user),
              icon: const Icon(Icons.close, size: 16),
            ),
        ],
      ),
    );
  }
}

class _InAppShareSheet extends StatelessWidget {
  const _InAppShareSheet({required this.text, required this.onCopy});

  final String text;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          0,
          AppSpacing.page,
          AppSpacing.page,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Share invite', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(text, style: theme.textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: onCopy,
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copy invite code'),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnavailableGroup extends StatelessWidget {
  const _UnavailableGroup({this.name});

  final String? name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(name ?? 'Group')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.page),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name == null
                    ? 'This group is no longer available.'
                    : 'You are no longer a member of $name. Join again with '
                          'its invite code to see it.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: () => Navigator.maybePop(context),
                child: const Text('Back to My Groups'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
