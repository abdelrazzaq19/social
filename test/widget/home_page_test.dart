import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quick_social/pages/pages.dart';

import '../helpers/known_defects.dart';
import '../helpers/mock_network_images.dart';
import '../helpers/pump_app.dart';

/// The notifications header is a fixed `Row` whose long label does not fit a
/// phone, so visiting that tab overflows by ~200px. Tracked as E22 and fixed
/// in T10; these tests are about navigation, not that layout.
const String _notificationsOverflow =
    'E22 — NotificationsPage header Row overflows at phone width';

void main() {
  setUpMockNetworkImages();

  Future<void> pumpHome(WidgetTester tester, {Size size = phoneSize}) async {
    await pumpApp(tester, const HomePage(), surfaceSize: size);
    await tester.pump(const Duration(milliseconds: 100));
  }

  group('HomePage navigation', () {
    testWidgets('opens on the feed', (tester) async {
      await pumpHome(tester);

      expect(find.byType(FeedPage), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(_selectedIndex(tester), 0);
    });

    testWidgets('tapping a destination changes the page', (tester) async {
      await pumpHome(tester);

      await tester.tap(find.byIcon(Icons.notifications_outlined));
      await tester.pumpAndSettle();
      drainKnownOverflows(tester, reason: _notificationsOverflow);

      expect(find.byType(NotificationsPage), findsOneWidget);
      expect(_selectedIndex(tester), 1);

      await tester.tap(find.byIcon(Icons.person_outlined));
      await tester.pumpAndSettle();
      drainKnownOverflows(tester, reason: _notificationsOverflow);

      expect(find.byType(ProfilePage), findsOneWidget);
      expect(_selectedIndex(tester), 2);
    });

    testWidgets('jumping two destinations at once lands on the right page',
        (tester) async {
      await pumpHome(tester);

      // 0 -> 2 is not adjacent: the implementation jumps rather than sweeping
      // through the page in between.
      await tester.tap(find.byIcon(Icons.person_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(ProfilePage), findsOneWidget);
      expect(find.byType(NotificationsPage), findsNothing);
      expect(_selectedIndex(tester), 2);
    });

    testWidgets('swiping the page view keeps the indicator in sync',
        (tester) async {
      await pumpHome(tester);

      await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
      await tester.pumpAndSettle();
      drainKnownOverflows(tester, reason: _notificationsOverflow);

      expect(find.byType(NotificationsPage), findsOneWidget);
      expect(_selectedIndex(tester), 1);
    });

    testWidgets('switching tabs repeatedly throws nothing unexpected',
        (tester) async {
      await pumpHome(tester);

      for (var i = 0; i < 20; i++) {
        final IconData icon = switch (i % 3) {
          0 => Icons.home_outlined,
          1 => Icons.notifications_outlined,
          _ => Icons.person_outlined,
        };

        // The selected destination renders its filled icon, so its outlined
        // variant is absent — skip those turns rather than tapping nothing.
        final Finder finder = find.byIcon(icon);
        if (finder.evaluate().isEmpty) continue;

        await tester.tap(finder);
        await tester.pumpAndSettle();
      }

      // Rethrows anything that is not the known overflow.
      drainKnownOverflows(tester, reason: _notificationsOverflow);
    });

    testWidgets('disposing the page disposes its controller', (tester) async {
      await pumpHome(tester);

      final PageView pageView = tester.widget(find.byType(PageView));
      final PageController controller = pageView.controller!;

      await tester.pumpWidget(const SizedBox());
      await tester.pump();

      // A disposed ChangeNotifier throws when a listener is added to it.
      expect(() => controller.addListener(() {}), throwsFlutterError);
    });

    // Back at tablet width now that E21 is fixed: the 768-1024 band used to
    // overflow the post action row, which failed this test for a reason that
    // had nothing to do with navigation.
    testWidgets('uses the rail instead of the bar at tablet width',
        (tester) async {
      await pumpHome(tester, size: tabletSize);

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('uses the rail at desktop width too', (tester) async {
      await pumpHome(tester, size: desktopSize);

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });
  });
}

int _selectedIndex(WidgetTester tester) {
  final Finder bar = find.byType(NavigationBar);
  if (bar.evaluate().isNotEmpty) {
    return (tester.widget(bar) as NavigationBar).selectedIndex;
  }
  return (tester.widget(find.byType(NavigationRail)) as NavigationRail)
      .selectedIndex!;
}
