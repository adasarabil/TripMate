import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../data/group_store.dart';
import '../../ui/app_theme.dart';
import '../../ui/app_widgets.dart';

/// 20 · Join Group. Pops with the joined group ID on success.
class JoinGroupScreen extends StatefulWidget {
  const JoinGroupScreen({super.key});

  @override
  State<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends State<JoinGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  String? _serverError;
  var _joined = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _join() {
    if (_joined) return;
    setState(() => _serverError = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final store = context.read<GroupStore>();
    final (result, groupId) = store.joinWithCode(_code.text);
    switch (result) {
      case JoinResult.notFound:
        setState(() => _serverError = 'No group found with this code');
      case JoinResult.alreadyMember:
        final name = store.byId(groupId!)?.name ?? 'this group';
        setState(() => _serverError = 'You are already a member of $name');
      case JoinResult.joined:
        _joined = true;
        final name = store.byId(groupId!)?.name ?? 'the group';
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('You joined $name.')));
        Navigator.pop(context, groupId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Join Group')),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.page),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: Image.asset(
                      AppAssets.joinGroup,
                      fit: BoxFit.contain,
                      semanticLabel: 'Friends joining a trip group',
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Got an invite code?',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(fontSize: 21),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Enter the code a friend shared with you to join their '
                  'travel group.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                TextFormField(
                  controller: _code,
                  autocorrect: false,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: 'Invite code',
                    hintText: 'TRP-XXXX',
                    errorText: _serverError,
                  ),
                  validator: (value) =>
                      GroupStore.normalizeCode(value ?? '').isEmpty
                      ? 'Enter an invite code'
                      : null,
                  onChanged: (_) {
                    if (_serverError != null) {
                      setState(() => _serverError = null);
                    }
                  },
                  onFieldSubmitted: (_) => _join(),
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton(onPressed: _join, child: const Text('Join Group')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
