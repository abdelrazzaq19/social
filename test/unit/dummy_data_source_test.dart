import 'package:flutter_test/flutter_test.dart';
import 'package:quick_social/data/dummy_data_source.dart';
import 'package:quick_social/models/models.dart';

/// Fixed, so two sources built with the same seed are comparable down to
/// their timestamps.
final DateTime _fixedNow = DateTime.utc(2026, 9, 7, 12);

DummyDataSource _source({int seed = DummyDataSource.defaultSeed}) {
  return DummyDataSource(seed: seed, now: _fixedNow);
}

void main() {
  group('determinism', () {
    test('the same seed produces the same content', () {
      final a = _source();
      final b = _source();

      expect(a.users.map((u) => u.username), b.users.map((u) => u.username));
      expect(a.posts.map((p) => p.caption), b.posts.map((p) => p.caption));
      expect(a.posts.map((p) => p.postImage), b.posts.map((p) => p.postImage));
      expect(a.posts.map((p) => p.owner.id), b.posts.map((p) => p.owner.id));
      expect(a.posts.map((p) => p.createdAt), b.posts.map((p) => p.createdAt));
      expect(
        a.notifications.map((n) => n.type),
        b.notifications.map((n) => n.type),
      );
    });

    test('a different seed produces different content', () {
      final a = _source();
      final b = _source(seed: DummyDataSource.defaultSeed + 1);

      expect(
        a.users.map((u) => u.username),
        isNot(b.users.map((u) => u.username)),
      );
    });
  });

  group('coverage guarantees', () {
    test('every user owns at least one post — E7', () {
      final source = _source();
      final Set<String> owners =
          source.posts.map((post) => post.owner.id).toSet();

      expect(owners, source.users.map((user) => user.id).toSet());
    });

    test('every user appears in at least one comment — E7', () {
      final source = _source();
      final Set<String> commenters = source.posts
          .expand((post) => post.comments)
          .map((comment) => comment.owner.id)
          .toSet();

      expect(commenters, source.users.map((user) => user.id).toSet());
    });

    test('every notification type is produced, including follow — E6', () {
      final source = _source();
      final Set<NotificationType> types =
          source.notifications.map((n) => n.type).toSet();

      expect(types, NotificationType.values.toSet());
    });

    test('comment counts span zero to a dozen — E5', () {
      final source = _source();
      final List<int> counts =
          source.posts.map((post) => post.comments.length).toList();

      // Zero-comment posts are realistic and the sheet has an empty state for
      // them since T8, so they are allowed again. Most posts still have some.
      expect(counts.every((count) => count <= 12), isTrue);
      expect(counts.where((count) => count > 0).length, greaterThan(20));
    });

    test('every user has a story', () {
      final source = _source();

      for (final User user in source.users) {
        expect(source.storyFor(user), isNotNull, reason: user.toString());
        expect(source.storyFor(user)!.stories, isNotEmpty);
      }
    });

    test('notifications are never about the signed-in user', () {
      final source = _source();

      for (final UserNotification notification in source.notifications) {
        expect(notification.actor.id, isNot(source.currentUser.id));
      }
    });
  });

  group('identity', () {
    test('ids are unique across each collection', () {
      final source = _source();

      expect(
        source.users.map((u) => u.id).toSet().length,
        source.users.length,
      );
      expect(
        source.posts.map((p) => p.id).toSet().length,
        source.posts.length,
      );
      expect(
        source.notifications.map((n) => n.id).toSet().length,
        source.notifications.length,
      );

      final List<Comment> comments =
          source.posts.expand((post) => post.comments).toList();
      expect(comments.map((c) => c.id).toSet().length, comments.length);
    });

    test('equality is by id, not by identity', () {
      final a = _source();
      final b = _source();

      expect(a.users.first, b.users.first);
      expect(a.users.first, isNot(same(b.users.first)));
      expect(a.posts.first, b.posts.first);
      expect(a.users.first, isNot(a.users.last));
    });

    test('models can be used as map keys and in sets', () {
      final source = _source();
      final Set<User> users = {...source.users, ...source.users};

      expect(users.length, source.users.length);
    });

    test('image urls are distinct per entity', () {
      final source = _source();
      final Set<String> avatars =
          source.users.map((user) => user.profileImage).toSet();
      final Set<String> postImages =
          source.posts.map((post) => post.postImage).toSet();

      expect(avatars.length, source.users.length);
      expect(postImages.length, source.posts.length);
    });
  });

  group('shape', () {
    test('the signed-in user is the only one flagged isMe', () {
      final source = _source();

      expect(source.users.where((user) => user.isMe).length, 1);
      expect(source.currentUser.isMe, isTrue);
    });

    test('posts are ordered newest first', () {
      final source = _source();

      for (var i = 1; i < source.posts.length; i++) {
        expect(
          source.posts[i].createdAt.isBefore(source.posts[i - 1].createdAt),
          isTrue,
          reason: 'post ${source.posts[i].id} is not older than the one before',
        );
      }
    });

    test('postsBy returns only that user\'s posts', () {
      final source = _source();
      final User user = source.users.last;

      final List<Post> posts = source.postsBy(user);

      expect(posts, isNotEmpty);
      expect(posts.every((post) => post.owner.id == user.id), isTrue);
    });

    test('no model exposes mutable static state', () {
      // A regression guard in prose: the previous design kept generated
      // content in `static` fields on the models, so any widget could mutate
      // the app's data by accident. Building two sources must not interfere.
      final a = _source();
      final b = _source();

      expect(identical(a.posts, b.posts), isFalse);
      expect(identical(a.users, b.users), isFalse);
    });
  });
}
