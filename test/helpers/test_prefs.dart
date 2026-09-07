import 'package:quick_social/services/prefs_service.dart';
import 'package:quick_social/state/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Opens a [PrefsService] backed by in-memory storage.
///
/// Pass [initialValues] to start a test from a known stored state. Keys must
/// be fully namespaced (`qs.v1.themeMode`), the same way they are on disk.
Future<PrefsService> createTestPrefs([
  Map<String, Object> initialValues = const {},
]) async {
  SharedPreferences.setMockInitialValues(initialValues);
  return PrefsService.fromPreferences(await SharedPreferences.getInstance());
}

/// A [ThemeController] over in-memory storage, with its stored value loaded.
Future<ThemeController> createTestThemeController([
  Map<String, Object> initialValues = const {},
]) async {
  return ThemeController(await createTestPrefs(initialValues))..load();
}
