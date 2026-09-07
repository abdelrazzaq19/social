import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quick_social/data/dummy_data_source.dart';
import 'package:quick_social/pages/pages.dart';
import 'package:quick_social/services/prefs_service.dart';
import 'package:quick_social/widgets/widgets.dart';

import '../helpers/known_defects.dart';
import '../helpers/mock_network_images.dart';
import '../helpers/pump_app.dart';
import '../helpers/test_prefs.dart';

const String _notificationsOverflow =
    'E22 — NotificationsPage header Row overflows at phone width';

void main() {
  setUpMockNetworkImages();

  /// Explicit pumps rather than `pumpAndSettle`: the feed builds every post
  /// eagerly (E12) and one image left in its loading builder keeps an
  /// indeterminate spinner running, so settling never completes.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  Future<void> pumpHome(
    WidgetTester tester, {
    PrefsService? prefs,
    Size size = phoneSize,
  }) async {
    await pumpApp(tester, const HomePage(), prefs: prefs, surfaceSize: size);
    await settle(tester);
  }

  Future<void> goToTab(WidgetTester tester, IconData icon) async {
    await tester.tap(find.byIcon(icon));
    await settle(tester);
    drainKnownOverflows(tester, reason: _notificationsOverflow);
  }

  group('interaction state outlives the widget — E16', () {
    testWidgets('a like survives leaving the feed and coming back',
        (tester) async {
      await pumpHome(tester);

      expect(find.byIcon(Icons.favorite), findsNothing);

      await tester.tap(find.byIcon(Icons.favorite_outline).first);
      await settle(tester);
      expect(find.byIcon(Icons.favorite), findsOneWidget);

      // Leaving the feed disposes the button. Under the old design that alone
      // was enough to lose the like.
      await goToTab(tester, Icons.person_outlined);
      await goToTab(tester, Icons.home_outlined);

      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('a save survives the same round trip', (tester) async {
      await pumpHome(tester);

      await tester.tap(find.byIcon(Icons.bookmark_outline).first);
      await settle(tester);
      expect(find.byIcon(Icons.bookmark), findsOneWidget);

      await goToTab(tester, Icons.person_outlined);
      await goToTab(tester, Icons.home_outlined);

      expect(find.byIcon(Icons.bookmark), findsOneWidget);
    });

    testWidgets('a like is written to storage, so it survives a relaunch',
        (tester) async {
      final PrefsService prefs = await createTestPrefs();

      await pumpHome(tester, prefs: prefs);

      await tester.tap(find.byIcon(Icons.favorite_outline).first);
      await settle(tester);

      expect(prefs.getStringList('likedPostIds'), isNotEmpty);
    });

    testWidgets('a stored like is shown on first build', (tester) async {
      final String postId =
          DummyDataSource(now: DateTime.utc(2026, 9, 7)).posts.first.id;

      await pumpHome(
        tester,
        prefs: await createTestPrefs({
          'qs.v1.likedPostIds': [postId],
        }),
      );

      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });
  });

  group('notification read state is single-sourced — E8', () {
    testWidgets('tapping a notification survives leaving the tab',
        (tester) async {
      await pumpHome(tester);
      await goToTab(tester, Icons.notifications_outlined);

      final int totalTiles = find.byType(NotificationTile).evaluate().length;
      expect(totalTiles, greaterThan(0));
      expect(_unreadCount(), totalTiles);

      await tester.tap(find.byType(NotificationTile).first);
      await settle(tester);
      drainKnownOverflows(tester, reason: _notificationsOverflow);

      expect(_unreadCount(), totalTiles - 1);

      await goToTab(tester, Icons.home_outlined);
      await goToTab(tester, Icons.notifications_outlined);

      expect(_unreadCount(), totalTiles - 1);
    });

    // At desktop width the notifications header fits, so the button is on
    // screen and can actually be tapped. At phone width E22 pushes it off the
    // right edge; T10 fixes that and this can move back to phoneSize.
    testWidgets('mark all read persists', (tester) async {
      final PrefsService prefs = await createTestPrefs();

      await pumpHome(tester, prefs: prefs, size: desktopSize);
      await goToTab(tester, Icons.notifications_outlined);

      expect(_unreadCount(), greaterThan(0));

      await tester.tap(find.text('Tandai telah dibaca'));
      await settle(tester);

      expect(_unreadCount(), 0);
      expect(
        prefs.getStringList('readNotificationIds').length,
        DummyDataSource.instance.notifications.length,
      );
    });
  });
}

int _unreadCount() => find.byKey(unreadDotKey).evaluate().length;
