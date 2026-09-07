import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quick_social/data/dummy_data_source.dart';
import 'package:quick_social/models/models.dart';
import 'package:quick_social/services/prefs_service.dart';
import 'package:quick_social/widgets/widgets.dart';

import '../helpers/mock_network_images.dart';
import '../helpers/pump_app.dart';
import '../helpers/test_prefs.dart';

final DateTime _now = DateTime.utc(2026, 9, 7, 12);

DummyDataSource _source() => DummyDataSource(now: _now);

/// The first post that actually has comments. Post counts include zero since
/// T8, so `posts.first` is not a safe assumption.
Post _postWithComments() {
  return _source().posts.firstWhere((post) => post.comments.isNotEmpty);
}

void main() {
  setUpMockNetworkImages();

  /// Pumps a button that opens the sheet, then opens it.
  Future<void> openSheet(
    WidgetTester tester,
    Post post, {
    PrefsService? prefs,
  }) async {
    await pumpApp(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => CommentsBottomSheet.showCommentsBottomSheet(
                context,
                post: post,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
      prefs: prefs,
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Post postWithNoComments() {
    final Post seed = _source().posts.first;
    return Post(
      id: 'p-empty',
      owner: seed.owner,
      postImage: seed.postImage,
      location: seed.location,
      caption: seed.caption,
      comments: const [],
      likeCount: 0,
      saveCount: 0,
      createdAt: _now,
    );
  }

  group('composing', () {
    testWidgets('submitting adds the comment and clears the field',
        (tester) async {
      // A post with no seeded comments, so the new one is on screen rather
      // than at the bottom of a long list.
      await openSheet(tester, postWithNoComments());

      await tester.enterText(find.byType(TextField), 'Nice shot');
      await tester.tap(find.byTooltip('Post comment'));
      await tester.pumpAndSettle();

      expect(find.text('Nice shot'), findsOneWidget);
      expect(find.text('1 comment'), findsOneWidget);

      final TextField field = tester.widget(find.byType(TextField));
      expect(field.controller?.text, isEmpty);
    });

    testWidgets('the count on the header follows the repository',
        (tester) async {
      final Post post = _postWithComments();
      await openSheet(tester, post);

      expect(find.text('${post.comments.length} comments'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'One more');
      await tester.tap(find.byTooltip('Post comment'));
      await tester.pumpAndSettle();

      expect(find.text('${post.comments.length + 1} comments'), findsOneWidget);
    });

    testWidgets('an empty submission does nothing', (tester) async {
      final Post post = _postWithComments();
      await openSheet(tester, post);

      final String headerBefore = _headerText(tester);

      await tester.tap(find.byTooltip('Post comment'));
      await tester.pumpAndSettle();

      expect(_headerText(tester), headerBefore);
    });

    testWidgets('a whitespace-only submission does nothing', (tester) async {
      final Post post = _postWithComments();
      await openSheet(tester, post);

      final String headerBefore = _headerText(tester);

      await tester.enterText(find.byType(TextField), '    ');
      await tester.tap(find.byTooltip('Post comment'));
      await tester.pumpAndSettle();

      expect(_headerText(tester), headerBefore);
    });

    testWidgets('the comment is trimmed', (tester) async {
      await openSheet(tester, postWithNoComments());

      await tester.enterText(find.byType(TextField), '   spaced   ');
      await tester.tap(find.byTooltip('Post comment'));
      await tester.pumpAndSettle();

      expect(find.text('spaced'), findsOneWidget);
    });

    testWidgets('the post does not gain the comment — only the repository does',
        (tester) async {
      final Post post = postWithNoComments();
      await openSheet(tester, post);

      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.tap(find.byTooltip('Post comment'));
      await tester.pumpAndSettle();

      expect(
        post.comments,
        isEmpty,
        reason: 'the sheet must not mutate shared app data',
      );
    });
  });

  group('empty state — E5', () {
    testWidgets('a post with no comments explains itself', (tester) async {
      await openSheet(tester, postWithNoComments());

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text('No comments yet'), findsOneWidget);
      expect(find.text('0 comments'), findsOneWidget);
    });

    testWidgets('the empty state goes away once a comment is added',
        (tester) async {
      await openSheet(tester, postWithNoComments());

      await tester.enterText(find.byType(TextField), 'First');
      await tester.tap(find.byTooltip('Post comment'));
      await tester.pumpAndSettle();

      expect(find.byType(EmptyState), findsNothing);
      expect(find.text('1 comment'), findsOneWidget);
    });
  });

  group('deleting', () {
    testWidgets('a comment the user wrote can be deleted', (tester) async {
      await openSheet(tester, postWithNoComments());

      await tester.enterText(find.byType(TextField), 'Mine to delete');
      await tester.tap(find.byTooltip('Post comment'));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Delete comment'), findsOneWidget);

      await tester.tap(find.byTooltip('Delete comment'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Mine to delete'), findsNothing);
      expect(find.byType(EmptyState), findsOneWidget);
    });

    testWidgets('cancelling the dialog keeps the comment', (tester) async {
      await openSheet(tester, postWithNoComments());

      await tester.enterText(find.byType(TextField), 'Keep me');
      await tester.tap(find.byTooltip('Post comment'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Delete comment'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Keep me'), findsOneWidget);
    });

    testWidgets('someone else\'s comment has no delete action', (tester) async {
      final DummyDataSource source = _source();
      final Post post = source.posts.firstWhere(
        (p) => p.comments.every((c) => !c.owner.isMe),
      );

      await openSheet(tester, post);

      expect(find.byTooltip('Delete comment'), findsNothing);
    });
  });

  group('likes', () {
    testWidgets('liking a comment updates the count', (tester) async {
      final Post post = _postWithComments();
      final Comment comment = post.comments.first;

      await openSheet(tester, post);

      expect(find.text('${comment.likeCount}'), findsWidgets);

      await tester.tap(find.byTooltip('Like comment').first);
      await tester.pumpAndSettle();

      expect(find.text('${comment.likeCount + 1}'), findsWidgets);
    });

    testWidgets('a comment like is written to storage', (tester) async {
      final PrefsService prefs = await createTestPrefs();
      final Post post = _postWithComments();

      await openSheet(tester, post, prefs: prefs);

      await tester.tap(find.byTooltip('Like comment').first);
      await tester.pumpAndSettle();

      expect(prefs.getStringList('likedCommentIds'), isNotEmpty);
    });

    testWidgets('a stored comment like shows on first build', (tester) async {
      final Post post = _postWithComments();
      final Comment comment = post.comments.first;

      await openSheet(
        tester,
        post,
        prefs: await createTestPrefs({
          'qs.v1.likedCommentIds': [comment.id],
        }),
      );

      expect(find.byTooltip('Unlike comment'), findsOneWidget);
    });
  });

  testWidgets('the sheet is draggable', (tester) async {
    await openSheet(tester, _postWithComments());

    expect(find.byType(DraggableScrollableSheet), findsOneWidget);
  });
}

String _headerText(WidgetTester tester) {
  return tester
      .widget<Text>(find.textContaining('comment').first)
      .data!;
}
