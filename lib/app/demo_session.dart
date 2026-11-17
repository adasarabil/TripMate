import 'package:material_ui/material_ui.dart';

enum AppMainTab { trips, groups, profile }

class DemoSession extends ChangeNotifier {
  AppMainTab _currentTab = AppMainTab.trips;
  String _defaultCurrencyCode = 'EUR';
  ThemeMode _themeMode = ThemeMode.system;
  String _languageCode = 'en';
  bool _notificationsEnabled = true;

  AppMainTab get currentTab => _currentTab;
  String get currentUserId => 'ada';
  String get defaultCurrencyCode => _defaultCurrencyCode;
  ThemeMode get themeMode => _themeMode;
  String get languageCode => _languageCode;
  bool get notificationsEnabled => _notificationsEnabled;

  void selectTab(AppMainTab tab) {
    if (_currentTab == tab) return;
    _currentTab = tab;
    notifyListeners();
  }

  void setDefaultCurrencyCode(String code) {
    if (_defaultCurrencyCode == code) return;
    _defaultCurrencyCode = code;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
  }

  void setLanguageCode(String code) {
    if (_languageCode == code) return;
    _languageCode = code;
    notifyListeners();
  }

  void setNotificationsEnabled(bool enabled) {
    if (_notificationsEnabled == enabled) return;
    _notificationsEnabled = enabled;
    notifyListeners();
  }
}
