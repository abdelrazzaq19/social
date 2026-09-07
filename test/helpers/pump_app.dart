import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quick_social/repositories/repositories.dart';
import 'package:quick_social/services/prefs_service.dart';
import 'package:quick_social/state/theme_controller.dart';
import 'package:quick_social/theme/app_theme.dart';

import 'test_prefs.dart';

/// Reference viewport sizes, so tests state the breakpoint they exercise
/// instead of relying on the binding's 800x600 default — which sits awkwardly
/// just inside the app's tablet breakpoint (768).
const Size phoneSize = Size(390, 844);
const Size tabletSize = Size(834, 1112);
const Size desktopSize = Size(1440, 900);

/// The theme widget tests render against — the same one the app ships.
ThemeData testAppTheme() => AppTheme.light();

/// Sets the test viewport to [size] and restores it when the test ends.
///
/// Uses `tester.view` rather than `binding.setSurfaceSize`: the latter does
/// not reach `MediaQuery`, so the widget under test still sees the default
/// 800x600 and silently renders the wrong breakpoint.
Future<void> setSurfaceSize(WidgetTester tester, Size size) async {
  tester.view
    ..devicePixelRatio = 1.0
    ..physicalSize = size;
  addTearDown(tester.view.reset);
}

/// Pumps [widget] inside a [MaterialApp] carrying the app theme, with the
/// repositories the app provides at its root.
///
/// Use this instead of `tester.pumpWidget(MaterialApp(home: ...))` so tests
/// exercise the same theme and the same state layer the app ships. Pass
/// [prefs] to start from stored state, or to inspect what a widget wrote.
Future<void> pumpApp(
  WidgetTester tester,
  Widget widget, {
  ThemeData? theme,
  Size surfaceSize = phoneSize,
  PrefsService? prefs,
}) async {
  await setSurfaceSize(tester, surfaceSize);

  final PrefsService resolved = prefs ?? await createTestPrefs();

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeController(resolved)..load()),
        ChangeNotifierProvider(create: (_) => FeedRepository(resolved)),
        ChangeNotifierProvider(create: (_) => CommentRepository(resolved)),
        ChangeNotifierProvider(create: (_) => SocialRepository(resolved)),
        ChangeNotifierProvider(create: (_) => StoryRepository(resolved)),
        ChangeNotifierProvider(create: (_) => NotificationRepository(resolved)),
      ],
      child: MaterialApp(
        theme: theme ?? testAppTheme(),
        debugShowCheckedModeBanner: false,
        home: widget,
      ),
    ),
  );
}
