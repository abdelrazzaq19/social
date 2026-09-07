import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quick_social/data/dummy_data_source.dart';
import 'package:quick_social/pages/pages.dart';
import 'package:quick_social/widgets/widgets.dart';

import '../helpers/mock_network_images.dart';
import '../helpers/pump_app.dart';

void main() {
  setUpMockNetworkImages();

  /// Past the simulated fetch, then one more frame.
  ///
  /// `pumpAndSettle` is not enough on its own: a pending `Timer` schedules no
  /// frames, so settling returns before the fetch has fired.
  Future<void> settleFetch(WidgetTester tester) async {
    await tester.pump(FeedPage.fetchDelay + const Duration(milliseconds: 50));
    await tester.pump();
  }

  Future<void> scrollToBottom(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -800));
      await tester.pump();
    }
  }

  /// Walks back to the top. Pull-to-refresh only arms at the top of the list,
  /// so a fling from deep in the feed just scrolls.
  Future<void> scrollToTop(WidgetTester tester) async {
    for (var i = 0; i < 40; i++) {
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 800));
      await tester.pump();
    }
  }

  int cardCount() => find.byType(PostCard).evaluate().length;

  bool isCaughtUp() =>
      find.text('You are all caught up').evaluate().isNotEmpty;

  group('loading', () {
    testWidgets('shows skeletons before the content arrives', (tester) async {
      await pumpApp(tester, const FeedPage());
      await tester.pump();

      expect(find.byType(PostSkeleton), findsWidgets);
      expect(find.byType(StoryRailSkeleton), findsOneWidget);
      expect(find.byType(PostCard), findsNothing);

      await settleFetch(tester);

      expect(find.byType(PostSkeleton), findsNothing);
      expect(find.byType(PostCard), findsWidgets);
    });

    testWidgets('the loading state settles instead of animating forever',
        (tester) async {
      await pumpApp(tester, const FeedPage());
      await tester.pump();

      // A shimmer here would make this call hang. Keeping the loading state
      // still is what lets every other test use pumpAndSettle at all.
      await tester.pumpAndSettle();

      expect(find.byType(PostSkeleton), findsWidgets);

      await settleFetch(tester);
      expect(find.byType(PostCard), findsWidgets);
    });
  });

  group('lazy building — E12', () {
    testWidgets('builds only the posts near the viewport', (tester) async {
      await pumpApp(tester, const FeedPage());
      await settleFetch(tester);

      final int total = DummyDataSource.instance.posts.length;

      expect(total, 30);
      expect(cardCount(), lessThan(total));
      expect(
        cardCount(),
        lessThanOrEqualTo(FeedPage.pageSize),
        reason: 'a page is $total posts; only a handful should be built',
      );
    });

    testWidgets('a footer spinner shows while the next page loads',
        (tester) async {
      await pumpApp(tester, const FeedPage());
      await settleFetch(tester);

      await scrollToBottom(tester);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await settleFetch(tester);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('paging walks to the end, then says so', (tester) async {
      await pumpApp(tester, const FeedPage());
      await settleFetch(tester);

      expect(isCaughtUp(), isFalse);

      // Enough rounds to walk through every page of 8.
      for (var i = 0; i < 8; i++) {
        await scrollToBottom(tester);
        await settleFetch(tester);
      }

      expect(isCaughtUp(), isTrue);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('refresh', () {
    testWidgets('pull to refresh shows the indicator and reloads',
        (tester) async {
      await pumpApp(tester, const FeedPage());
      await settleFetch(tester);
      expect(find.byType(PostCard), findsWidgets);

      await tester.fling(
        find.byType(CustomScrollView),
        const Offset(0, 400),
        1000,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(RefreshProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();
      await settleFetch(tester);

      expect(find.byType(PostCard), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('refreshing goes back to the first page', (tester) async {
      await pumpApp(tester, const FeedPage());
      await settleFetch(tester);

      for (var i = 0; i < 8; i++) {
        await scrollToBottom(tester);
        await settleFetch(tester);
      }
      expect(isCaughtUp(), isTrue);

      await scrollToTop(tester);
      await tester.fling(
        find.byType(CustomScrollView),
        const Offset(0, 600),
        1200,
      );
      await tester.pumpAndSettle();
      await settleFetch(tester);

      expect(isCaughtUp(), isFalse, reason: 'refresh should reset the paging');
      expect(find.byType(PostCard), findsWidgets);
    });
  });

  group('empty state', () {
    Widget emptyFeed() {
      return FeedPage(
        source: DummyDataSource(postCount: 0, now: DateTime.utc(2026, 9, 7)),
      );
    }

    testWidgets('an empty feed explains itself instead of going blank',
        (tester) async {
      await pumpApp(tester, emptyFeed());
      await settleFetch(tester);

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text('Nothing here yet'), findsOneWidget);
      expect(find.byType(PostCard), findsNothing);
    });

    testWidgets('an empty feed can still be pulled to refresh', (tester) async {
      await pumpApp(tester, emptyFeed());
      await settleFetch(tester);

      await tester.fling(
        find.byType(CustomScrollView),
        const Offset(0, 400),
        1000,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(RefreshProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();
      await settleFetch(tester);
    });
  });

  testWidgets('leaving mid-fetch does not leave a timer pending',
      (tester) async {
    await pumpApp(tester, const FeedPage());
    await tester.pump(const Duration(milliseconds: 50));

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
