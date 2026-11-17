import 'package:material_ui/material_ui.dart';

import '../ui/app_theme.dart';
import 'step22_routes.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen.logIn({super.key}) : isSignUp = false;
  const AuthScreen.signUp({super.key}) : isSignUp = true;

  final bool isSignUp;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  static final _emailPattern = RegExp(r'^[^\s@]+@[^\s@.]+(?:\.[^\s@.]+)+$');

  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  var _showPassword = false;
  var _submitted = false;
  var _openingHome = false;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (_openingHome) return;
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) return;

    _openingHome = true;
    FocusScope.of(context).unfocus();
    AppRoute.openHome(context);
  }

  @override
  Widget build(BuildContext context) {
    final isSignUp = widget.isSignUp;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(isSignUp ? 'Sign Up' : 'Log In')),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.xxl,
            AppSpacing.page,
            AppSpacing.xl,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                autovalidateMode: _submitted
                    ? AutovalidateMode.onUserInteraction
                    : AutovalidateMode.disabled,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      isSignUp ? 'Create account' : 'Welcome back',
                      style: theme.textTheme.headlineSmall,
                    ),
                    if (!isSignUp) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Log in to see your trips',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    if (isSignUp) ...[
                      TextFormField(
                        key: const Key('auth-username'),
                        decoration: _fieldDecoration('Username'),
                        textInputAction: TextInputAction.next,
                        validator: (value) => (value ?? '').trim().isEmpty
                            ? 'Enter a username'
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                    TextFormField(
                      key: const Key('auth-email'),
                      decoration: _fieldDecoration('Email'),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      validator: (value) =>
                          _emailPattern.hasMatch((value ?? '').trim())
                          ? null
                          : 'Enter a valid email address',
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    TextFormField(
                      key: const Key('auth-password'),
                      controller: _password,
                      decoration: _fieldDecoration('Password').copyWith(
                        suffixIcon: IconButton(
                          tooltip: _showPassword
                              ? 'Hide password'
                              : 'Show password',
                          icon: Icon(
                            _showPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            size: 18,
                          ),
                          onPressed: () => setState(() {
                            _showPassword = !_showPassword;
                          }),
                        ),
                      ),
                      obscureText: !_showPassword,
                      autocorrect: false,
                      enableSuggestions: false,
                      textInputAction: isSignUp
                          ? TextInputAction.next
                          : TextInputAction.done,
                      validator: (value) => (value ?? '').length < 6
                          ? 'Password must be at least 6 characters'
                          : null,
                      onFieldSubmitted: isSignUp ? null : (_) => _submit(),
                    ),
                    if (isSignUp) ...[
                      const SizedBox(height: AppSpacing.xl),
                      TextFormField(
                        key: const Key('auth-confirm-password'),
                        decoration: _fieldDecoration('Confirm password'),
                        obscureText: true,
                        autocorrect: false,
                        enableSuggestions: false,
                        textInputAction: TextInputAction.done,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Confirm your password';
                          }
                          return value == _password.text
                              ? null
                              : 'Passwords do not match';
                        },
                        onFieldSubmitted: (_) => _submit(),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xxl),
                    FilledButton(
                      onPressed: _submit,
                      child: Text(isSignUp ? 'Create Account' : 'Log In'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextButton(
                      onPressed: () =>
                          Navigator.pushReplacementNamed<void, void>(
                            context,
                            isSignUp ? AppRoute.logIn : AppRoute.signUp,
                          ),
                      child: Text(
                        isSignUp
                            ? 'Already have an account? Log in'
                            : "Don't have an account? Sign up",
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String label) => InputDecoration(
    labelText: label,
    floatingLabelBehavior: FloatingLabelBehavior.always,
  );
}
