import 'package:material_ui/material_ui.dart';

import '../../data/demo_models.dart';

/// Square thumbnail with the first letter of a name.
class InitialThumb extends StatelessWidget {
  const InitialThumb(this.name, {super.key, this.size = 44});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final letter = name.trim().isEmpty ? '?' : name.trim().characters.first;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        letter.toUpperCase(),
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String memberLabel(int count) => '$count ${count == 1 ? 'member' : 'members'}';

String tripLabel(int count) => '$count ${count == 1 ? 'trip' : 'trips'}';

/// Shows a Cancel/Confirm dialog and returns whether the user confirmed.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return confirmed == true && context.mounted;
}

/// Leave confirmation shared by My Groups and Group Detail.
Future<bool> confirmLeaveGroup(BuildContext context, Group group) =>
    confirmAction(
      context,
      title: 'Leave group?',
      message:
          'Leave “${group.name}”? It disappears from My Groups. Its trips '
          'and expenses stay, and you can join again with code '
          '${group.inviteCode}.',
      confirmLabel: 'Leave',
    );
