import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quick_social/state/theme_controller.dart';

import '../helpers/test_prefs.dart';

void main() {
  group('ThemeController', () {
    test('defaults to following the system', () async {
      final controller = await createTestThemeController();

      expect(controller.mode, ThemeMode.system);
    });

    test('loads a stored choice', () async {
      final controller = await createTestThemeController(
        {'qs.v1.themeMode': 'dark'},
      );

      expect(controller.mode, ThemeMode.dark);
    });

    test('falls back to system when the stored value is unrecognised',
        () async {
      final controller = await createTestThemeController(
        {'qs.v1.themeMode': 'sepia'},
      );

      expect(controller.mode, ThemeMode.system);
    });

    test('persists a change, and a fresh controller reads it back', () async {
      final prefs = await createTestPrefs();
      final controller = ThemeController(prefs)..load();

      await controller.setMode(ThemeMode.dark);

      final reopened = ThemeController(prefs)..load();
      expect(reopened.mode, ThemeMode.dark);
    });

    test('notifies listeners on change, but not on a no-op', () async {
      final controller = await createTestThemeController();
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.setMode(ThemeMode.dark);
      expect(notifications, 1);

      await controller.setMode(ThemeMode.dark);
      expect(notifications, 1, reason: 'setting the same mode should be inert');
    });
  });

  test('PrefsService discards keys from an older namespace', () async {
    final prefs = await createTestPrefs({
      'qs.v0.themeMode': 'dark',
      'qs.v1.themeMode': 'light',
      'unrelated.key': 'kept',
    });

    expect(prefs.getString('themeMode'), 'light');
  });
}
