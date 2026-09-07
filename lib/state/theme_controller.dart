import 'package:flutter/material.dart';
import 'package:quick_social/services/prefs_service.dart';

/// Holds the user's theme choice and persists it.
///
/// The default is [ThemeMode.system]: until the user says otherwise, the app
/// follows the device.
class ThemeController extends ChangeNotifier {
  ThemeController(this._prefs);

  static const String _key = 'themeMode';

  final PrefsService _prefs;

  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;

  /// Reads the stored choice. Call once before `runApp` so the first frame is
  /// already in the right theme.
  void load() {
    final String? stored = _prefs.getString(_key);
    if (stored == null) return;

    _mode = ThemeMode.values.firstWhere(
      (mode) => mode.name == stored,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) return;

    _mode = mode;
    notifyListeners();
    await _prefs.setString(_key, mode.name);
  }
}
