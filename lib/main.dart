import 'package:material_ui/material_ui.dart';

import 'ui/app_theme.dart';

void main() {
  runApp(
    MaterialApp(
      title: 'TripMate',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: Scaffold(appBar: AppBar(title: const Text('TripMate'))),
    ),
  );
}
