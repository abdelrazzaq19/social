import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quick_social/app.dart';
import 'package:quick_social/pages/pages.dart';
import 'package:quick_social/widgets/widgets.dart';

import '../helpers/mock_network_images.dart';
import '../helpers/pump_app.dart';
import '../helpers/test_prefs.dart';

void main() {
  setUpMockNetworkImages();

  /// Advances past the splash hold and lets the route transition finish.
  ///
  /// Explicit pumps rather than `pumpAndSettle`: the feed builds all 30 posts
  /// eagerly (E12), and a single image still in its loading builder keeps an
  /// indeterminate spinner running, so settling can time out.
  Future<void> openHome(WidgetTester tester) async {
    await tester.pump(SplashPage.holdDuration + const Duration(milliseconds: 1));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  Future<void> pumpMyApp(
    WidgetTester tester, {
    Map<String, Object> storedPrefs = const {},
  }) async {
    await setSurfaceSize(tester, phoneSize);
    await tester.pumpWidget(MyApp(prefs: await createTestPrefs(storedPrefs)));
  }

  testWidgets('boots to the splash screen showing the logo', (tester) async {
    await pumpMyApp(tester);

    expect(find.byType(SplashPage), findsOneWidget);
    expect(find.byType(AppLogo), findsOneWidget);
    expect(find.text('QuickSocial'), findsOneWidget);
  });

  testWidgets('splash hands off to the feed', (tester) async {
    await pumpMyApp(tester);

    await openHome(tester);

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(FeedPage), findsOneWidget);
    expect(find.byType(PostCard), findsWidgets);
  });

  testWidgets('splash is replaced, not stacked, so back does not return to it',
      (tester) async {
    await pumpMyApp(tester);

    await openHome(tester);

    // A pushed route would leave the splash in the tree, offstage beneath the
    // feed. Replacing it removes it outright.
    expect(find.byType(SplashPage, skipOffstage: false), findsNothing);
  });

  testWidgets('leaving the splash early cancels its pending navigation',
      (tester) async {
    await pumpMyApp(tester);

    // Tear the tree down mid-hold. If the timer outlived the state, the
    // binding would fail this test with a pending-timer assertion.
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('follows the system theme by default', (tester) async {
    await pumpMyApp(tester);

    final MaterialApp app = tester.widget(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.system);
    expect(app.theme, isNotNull);
    expect(app.darkTheme, isNotNull);
  });

  testWidgets('honours a stored theme choice on the first frame',
      (tester) async {
    await pumpMyApp(tester, storedPrefs: {'qs.v1.themeMode': 'dark'});

    final MaterialApp app = tester.widget(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
  });
}
