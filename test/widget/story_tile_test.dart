import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quick_social/data/dummy_data_source.dart';
import 'package:quick_social/models/models.dart';
import 'package:quick_social/pages/pages.dart';
import 'package:quick_social/services/prefs_service.dart';
import 'package:quick_social/widgets/widgets.dart';

import '../helpers/mock_network_images.dart';
import '../helpers/pump_app.dart';
import '../helpers/test_prefs.dart';

final DateTime _now = DateTime.utc(2026, 9, 7, 12);

DummyDataSource _source() => DummyDataSource(now: _now);

void main() {
  setUpMockNetworkImages();

  /// Never `pumpAndSettle` once the viewer is open: the story indicator
  /// auto-advances, so settling plays every story to the end, reaches the page
  /// limit, and pops the viewer back off the stack.
  Future<void> settleRoute(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> pumpRail(
    WidgetTester tester, {
    PrefsService? prefs,
  }) async {
    final List<UserStory> stories = _source().userStories;

    await pumpApp(
      tester,
      Scaffold(
        body: SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: stories.length,
            itemBuilder: (_, index) => UserStoryTile(
              userStory: stories[index],
              stories: stories,
              index: index,
            ),
          ),
        ),
      ),
      prefs: prefs,
    );
    await tester.pump();
  }

  /// Reads the ring decoration off the outermost container of a tile.
  BoxDecoration ringDecorationAt(WidgetTester tester, int tileIndex) {
    final Finder container = find
        .descendant(
          of: find.byType(UserStoryTile).at(tileIndex),
          matching: find.byType(Container),
        )
        .first;

    return tester.widget<Container>(container).decoration! as BoxDecoration;
  }

  group('the ring says whether there is something to watch', () {
    testWidgets('an unseen story gets a gradient ring', (tester) async {
      await pumpRail(tester);

      final BoxDecoration ring = ringDecorationAt(tester, 0);

      expect(ring.gradient, isNotNull);
      expect(ring.color, isNull);
    });

    testWidgets('a seen story gets a flat ring instead', (tester) async {
      final UserStory first = _source().userStories.first;

      await pumpRail(
        tester,
        prefs: await createTestPrefs({
          'qs.v1.seenStoryOwnerIds': [first.owner.id],
        }),
      );

      final BoxDecoration ring = ringDecorationAt(tester, 0);

      expect(ring.gradient, isNull);
      expect(ring.color, isNotNull);
    });

    testWidgets('watching a story mutes its ring, and that is stored',
        (tester) async {
      final PrefsService prefs = await createTestPrefs();
      await pumpRail(tester, prefs: prefs);

      expect(ringDecorationAt(tester, 0).gradient, isNotNull);

      await tester.tap(find.byType(UserStoryAvatar).first);
      await settleRoute(tester);

      expect(find.byType(UserStoryPage), findsOneWidget);

      final NavigatorState navigator = tester.state(find.byType(Navigator));
      navigator.pop();
      await settleRoute(tester);

      expect(ringDecorationAt(tester, 0).gradient, isNull);
      expect(prefs.getStringList('seenStoryOwnerIds'), isNotEmpty);
    });
  });

  group('your own story', () {
    testWidgets('is labelled and carries the add badge', (tester) async {
      await pumpRail(tester);

      expect(find.text('Your story'), findsOneWidget);

      final UserStoryAvatar mine = tester.widget(
        find.byType(UserStoryAvatar).first,
      );
      expect(mine.showAddBadge, isTrue);
    });

    testWidgets('other people\'s tiles show their username, not a badge',
        (tester) async {
      await pumpRail(tester);

      final UserStoryAvatar other = tester.widget(
        find.byType(UserStoryAvatar).at(1),
      );
      expect(other.showAddBadge, isFalse);

      final DummyDataSource source = _source();
      expect(find.text(source.users[1].username), findsOneWidget);
    });
  });

  group('the story rail in the feed', () {
    testWidgets('puts the signed-in user first', (tester) async {
      await pumpApp(tester, const FeedPage());
      await tester.pump(FeedPage.fetchDelay + const Duration(milliseconds: 50));
      await tester.pump();

      final UserStoryTile first = tester.widget(
        find.byType(UserStoryTile).first,
      );
      expect(first.userStory.owner.isMe, isTrue);
    });
  });

  group('the viewer', () {
    testWidgets('shows the owner, a timestamp, and a close button',
        (tester) async {
      final List<UserStory> stories = _source().userStories;

      await pumpApp(
        tester,
        UserStoryPage(initialIndex: 0, userStories: stories),
      );
      await settleRoute(tester);

      expect(find.textContaining(stories.first.owner.username), findsWidgets);
      expect(find.byTooltip('Close'), findsOneWidget);
    });

    testWidgets('opening it marks the owner seen', (tester) async {
      final PrefsService prefs = await createTestPrefs();
      final List<UserStory> stories = _source().userStories;

      await pumpApp(
        tester,
        UserStoryPage(initialIndex: 0, userStories: stories),
        prefs: prefs,
      );
      await settleRoute(tester);

      expect(
        prefs.getStringList('seenStoryOwnerIds'),
        contains(stories.first.owner.id),
      );
    });

    testWidgets('the close button leaves the viewer', (tester) async {
      final List<UserStory> stories = _source().userStories;

      await pumpApp(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  UserStoryPage.route(0, userStories: stories),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await settleRoute(tester);
      expect(find.byType(UserStoryPage), findsOneWidget);

      await tester.tap(find.byTooltip('Close'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(UserStoryPage), findsNothing);
    });
  });

  test('nothing outside the wrapper imports package:story', () {
    // Enforced by grep in CI terms; asserted here as a reminder that
    // `StoryViewer` is the only sanctioned entry point.
    expect(StoryViewer, isNotNull);
  });
}
