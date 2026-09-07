import 'package:flutter_test/flutter_test.dart';
import 'package:quick_social/data/dummy_data_source.dart';
import 'package:quick_social/models/models.dart';
import 'package:quick_social/repositories/feed_repository.dart';
import 'package:quick_social/services/prefs_service.dart';

import '../../helpers/test_prefs.dart';

void main() {
  late Post post;

  setUp(() {
    post = DummyDataSource(now: DateTime.utc(2026, 9, 7)).posts.first;
  });

  group('FeedRepository likes', () {
    test('starts with nothing liked', () async {
      final repository = FeedRepository(await createTestPrefs());

      expect(repository.isLiked(post.id), isFalse);
      expect(repository.likeCount(post), post.likeCount);
    });

    test('toggling on adds the user\'s own like to the count', () async {
      final repository = FeedRepository(await createTestPrefs());

      await repository.toggleLike(post.id);

      expect(repository.isLiked(post.id), isTrue);
      expect(repository.likeCount(post), post.likeCount + 1);
    });

    test('toggling twice returns to the original state', () async {
      final repository = FeedRepository(await createTestPrefs());

      await repository.toggleLike(post.id);
      await repository.toggleLike(post.id);

      expect(repository.isLiked(post.id), isFalse);
      expect(repository.likeCount(post), post.likeCount);
    });

    test('notifies listeners on every toggle', () async {
      final repository = FeedRepository(await createTestPrefs());
      var notifications = 0;
      repository.addListener(() => notifications++);

      await repository.toggleLike(post.id);
      await repository.toggleLike(post.id);

      expect(notifications, 2);
    });

    test('survives a restart', () async {
      final PrefsService prefs = await createTestPrefs();
      await FeedRepository(prefs).toggleLike(post.id);

      // A second repository over the same storage stands in for a relaunch.
      final reopened = FeedRepository(prefs);

      expect(reopened.isLiked(post.id), isTrue);
    });

    test('tracks each post independently', () async {
      final source = DummyDataSource(now: DateTime.utc(2026, 9, 7));
      final repository = FeedRepository(await createTestPrefs());

      await repository.toggleLike(source.posts[0].id);
      await repository.toggleLike(source.posts[2].id);

      expect(repository.isLiked(source.posts[0].id), isTrue);
      expect(repository.isLiked(source.posts[1].id), isFalse);
      expect(repository.isLiked(source.posts[2].id), isTrue);
    });
  });

  group('FeedRepository saves', () {
    test('save is independent of like', () async {
      final repository = FeedRepository(await createTestPrefs());

      await repository.toggleSave(post.id);

      expect(repository.isSaved(post.id), isTrue);
      expect(repository.isLiked(post.id), isFalse);
      expect(repository.saveCount(post), post.saveCount + 1);
    });

    test('exposes the saved set for the saved-posts page', () async {
      final source = DummyDataSource(now: DateTime.utc(2026, 9, 7));
      final repository = FeedRepository(await createTestPrefs());

      await repository.toggleSave(source.posts[1].id);
      await repository.toggleSave(source.posts[4].id);

      expect(
        repository.savedPostIds,
        {source.posts[1].id, source.posts[4].id},
      );
    });

    test('survives a restart', () async {
      final PrefsService prefs = await createTestPrefs();
      await FeedRepository(prefs).toggleSave(post.id);

      expect(FeedRepository(prefs).isSaved(post.id), isTrue);
    });
  });

  test('reads state stored under the versioned namespace', () async {
    final PrefsService prefs = await createTestPrefs({
      'qs.v1.likedPostIds': ['p1', 'p2'],
    });

    final repository = FeedRepository(prefs);

    expect(repository.isLiked('p1'), isTrue);
    expect(repository.isLiked('p2'), isTrue);
    expect(repository.isLiked('p3'), isFalse);
  });
}
