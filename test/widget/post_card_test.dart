import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quick_social/data/dummy_data_source.dart';
import 'package:quick_social/models/models.dart';
import 'package:quick_social/pages/pages.dart';
import 'package:quick_social/widgets/widgets.dart';

import '../helpers/mock_network_images.dart';
import '../helpers/pump_app.dart';

final DateTime _now = DateTime.utc(2026, 9, 7, 12);

DummyDataSource _source() => DummyDataSource(now: _now);

/// Every width the app is expected to survive: small Android phones through
/// to a wide desktop window.
const List<double> _widths = [
  360,
  390,
  430,
  600,
  768,
  800,
  834,
  900,
  1024,
  1200,
  1440,
];

void main() {
  setUpMockNetworkImages();

  Future<void> settleFeed(WidgetTester tester) async {
    await tester.pump(FeedPage.fetchDelay + const Duration(milliseconds: 50));
    await tester.pump();
  }

  group('layout — E21', () {
    for (final double width in _widths) {
      testWidgets('the whole feed lays out cleanly at ${width.toInt()}px',
          (tester) async {
        await pumpApp(
          tester,
          const HomePage(),
          surfaceSize: Size(width, 900),
        );
        await settleFeed(tester);

        expect(
          tester.takeException(),
          isNull,
          reason: 'overflow at ${width.toInt()}px',
        );
      });
    }

    testWidgets('a very long caption and username do not overflow',
        (tester) async {
      final Post post = _postWith(
        caption: 'A ' * 250,
        username: 'a_very_long_username_that_keeps_going_and_going_and_going',
      );

      for (final double width in [360.0, 800.0, 1440.0]) {
        await pumpApp(
          tester,
          Scaffold(
            body: ListView(children: [PostCard(post: post)]),
          ),
          surfaceSize: Size(width, 900),
        );
        await tester.pump();

        expect(
          tester.takeException(),
          isNull,
          reason: 'long content overflowed at ${width.toInt()}px',
        );
      }
    });

    testWidgets('a five-digit count does not overflow the action row',
        (tester) async {
      final Post post = _postWith(likeCount: 99999, saveCount: 88888);

      await pumpApp(
        tester,
        Scaffold(body: ListView(children: [PostCard(post: post)])),
        surfaceSize: const Size(360, 900),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });

  group('interactions', () {
    testWidgets('tapping like updates the icon and the count', (tester) async {
      final Post post = _source().posts.first;

      await pumpApp(
        tester,
        Scaffold(body: ListView(children: [PostCard(post: post)])),
      );
      await tester.pump();

      expect(find.text('${post.likeCount}'), findsOneWidget);
      expect(find.byIcon(Icons.favorite_outline), findsOneWidget);

      await tester.tap(find.byIcon(Icons.favorite_outline));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.text('${post.likeCount + 1}'), findsOneWidget);
    });

    testWidgets('double-tapping the image likes the post', (tester) async {
      final Post post = _source().posts.first;

      await pumpApp(
        tester,
        Scaffold(body: ListView(children: [PostCard(post: post)])),
      );
      await tester.pump();

      await _doubleTapImage(tester);

      expect(find.byIcon(Icons.favorite), findsWidgets);
      expect(find.text('${post.likeCount + 1}'), findsOneWidget);
    });

    testWidgets('double-tapping again does not unlike', (tester) async {
      final Post post = _source().posts.first;

      await pumpApp(
        tester,
        Scaffold(body: ListView(children: [PostCard(post: post)])),
      );
      await tester.pump();

      await _doubleTapImage(tester);
      await _doubleTapImage(tester);

      expect(find.text('${post.likeCount + 1}'), findsOneWidget);
    });

    testWidgets('the like burst finishes rather than animating forever',
        (tester) async {
      await pumpApp(
        tester,
        Scaffold(body: ListView(children: [PostCard(post: _source().posts.first)])),
      );
      await tester.pump();

      await _doubleTapImage(tester);

      // Would hang if the burst repeated.
      await tester.pumpAndSettle();
    });

    testWidgets('saving is independent of liking', (tester) async {
      final Post post = _source().posts.first;

      await pumpApp(
        tester,
        Scaffold(body: ListView(children: [PostCard(post: post)])),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.bookmark_outline));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.bookmark), findsOneWidget);
      expect(find.byIcon(Icons.favorite_outline), findsOneWidget);
      expect(find.text('${post.saveCount + 1}'), findsOneWidget);
    });
  });

  group('presentation', () {
    testWidgets('shows a relative timestamp', (tester) async {
      final Post post = _postWith(
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      );

      await pumpApp(
        tester,
        Scaffold(body: ListView(children: [PostCard(post: post)])),
      );
      await tester.pump();

      expect(find.textContaining('3h'), findsOneWidget);
    });

    testWidgets('every action carries a tooltip', (tester) async {
      await pumpApp(
        tester,
        Scaffold(
          body: ListView(children: [PostCard(post: _source().posts.first)]),
        ),
      );
      await tester.pump();

      for (final String label in ['Like', 'Comments', 'Save', 'Share']) {
        expect(
          find.byTooltip(label),
          findsOneWidget,
          reason: 'missing tooltip: $label',
        );
      }
    });

    testWidgets('a broken image falls back to the error widget',
        (tester) async {
      AppNetworkImage.debugProviderOverride =
          (_) => const _BrokenImageProvider();

      await pumpApp(
        tester,
        Scaffold(
          body: ListView(children: [PostCard(post: _source().posts.first)]),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(ErrorImageWidget), findsWidgets);
    });

    testWidgets('an avatar that fails to load shows the owner\'s initial',
        (tester) async {
      AppNetworkImage.debugProviderOverride =
          (_) => const _BrokenImageProvider();

      final Post post = _postWith(username: 'zoe_example');

      await pumpApp(
        tester,
        Scaffold(body: ListView(children: [PostCard(post: post)])),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Z'), findsOneWidget);
    });
  });
}

Future<void> _doubleTapImage(WidgetTester tester) async {
  final Finder image = find.byType(AppNetworkImage).last;

  await tester.tap(image);
  await tester.pump(const Duration(milliseconds: 50));
  await tester.tap(image);
  await tester.pump();

  // The double-tap recogniser leaves a short countdown timer behind; let it
  // expire or the binding fails the test with a pending timer.
  await tester.pump(const Duration(milliseconds: 500));
}

Post _postWith({
  String caption = 'A caption',
  String username = 'someone',
  int likeCount = 10,
  int saveCount = 5,
  DateTime? createdAt,
}) {
  final User owner = User(
    id: 'u-test',
    profileImage: 'https://example.test/avatar.jpg',
    bannerImage: 'https://example.test/banner.jpg',
    username: username,
    fullname: 'Test Person',
    bio: 'bio',
    followersCount: 1,
    followingCount: 1,
  );

  return Post(
    id: 'p-test',
    owner: owner,
    postImage: 'https://example.test/post.jpg',
    location: 'Somewhere, Nowhere',
    caption: caption,
    comments: const [],
    likeCount: likeCount,
    saveCount: saveCount,
    createdAt: createdAt ?? _now,
  );
}

/// Always fails to resolve, so the error path can be asserted.
class _BrokenImageProvider extends ImageProvider<_BrokenImageProvider> {
  const _BrokenImageProvider();

  @override
  Future<_BrokenImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<_BrokenImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(
    _BrokenImageProvider key,
    ImageDecoderCallback decode,
  ) {
    return OneFrameImageStreamCompleter(
      Future<ImageInfo>.error(Exception('broken image')),
    );
  }
}
