import 'package:material_ui/material_ui.dart';

import '../ui/app_theme.dart';
import '../ui/app_widgets.dart';
import 'step22_routes.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.page,
              constraints.maxHeight >= 690 ? 74 : AppSpacing.xl,
              AppSpacing.page,
              AppSpacing.xl,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        foregroundColor: theme.colorScheme.onSurface,
                        child: Text('TM', style: theme.textTheme.headlineSmall),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.page),
                    Text(
                      'TripMate',
                      style: theme.textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Plan multi-city trips with friends',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AspectRatio(
                      aspectRatio: 350 / 230,
                      child: DecoratedBox(
                        position: DecorationPosition.foreground,
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.colorScheme.outline),
                        ),
                        child: const AppImage(asset: AppAssets.welcome),
                      ),
                    ),
                    const SizedBox(height: 40),
                    FilledButton(
                      onPressed: () =>
                          Navigator.pushNamed<void>(context, AppRoute.logIn),
                      child: const Text('Log In'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton(
                      onPressed: () =>
                          Navigator.pushNamed<void>(context, AppRoute.signUp),
                      child: const Text('Sign Up'),
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
}
