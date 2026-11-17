import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'app/demo_session.dart';
import 'app/step22_routes.dart';
import 'data/expense_store.dart';
import 'data/group_store.dart';
import 'data/places_store.dart';
import 'data/trip_store.dart';
import 'ui/app_theme.dart';

void main() => runApp(const TripMateApp());

class TripMateApp extends StatelessWidget {
  const TripMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DemoSession()),
        ChangeNotifierProvider(create: (_) => TripStore()),
        ChangeNotifierProvider(create: (_) => GroupStore()),
        ChangeNotifierProvider(create: (_) => PlacesStore()),
        ChangeNotifierProvider(create: (_) => ExpenseStore()),
      ],
      builder: (context, _) {
        final themeMode = context.select(
          (DemoSession session) => session.themeMode,
        );
        final languageCode = context.select(
          (DemoSession session) => session.languageCode,
        );
        return MaterialApp(
          title: 'TripMate',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          locale: Locale(languageCode),
          initialRoute: AppRoute.welcome,
          onGenerateRoute: AppRoute.generate,
        );
      },
    );
  }
}
