import 'dart:math';

import 'package:faker/faker.dart';
import 'package:quick_social/models/models.dart';

/// Generates the app's sample content.
///
/// Everything comes from one seeded [Random] and one seeded [Faker], so the
/// same seed produces the same users, posts, comments, stories, and
/// notifications on every run. That is what makes the content stable enough to
/// assert against in tests, and it is why the generator lives here rather than
/// in `static` fields scattered across the model classes.
///
/// Coverage is guaranteed by construction, not left to chance: the first few
/// items of each collection are assigned round-robin so that every user owns a
/// post and appears in a comment, and every [NotificationType] occurs.
class DummyDataSource {
  DummyDataSource({
    this.seed = defaultSeed,
    DateTime? now,
    this.postCount = _defaultPostCount,
  })  : _random = Random(seed),
        _faker = Faker(seed: seed),
        _now = now ?? DateTime.now() {
    users = _generateUsers();
    posts = _generatePosts();
    userStories = _generateUserStories();
    notifications = _generateNotifications();
  }

  static const int defaultSeed = 20260907;

  static const int _userCount = 5;
  static const int _defaultPostCount = 30;
  static const int _notificationCount = 8;

  /// The instance the widget layer reads from.
  ///
  /// T6 replaces these direct reads with repositories provided at the root;
  /// this exists so the app keeps working in the meantime.
  static final DummyDataSource instance = DummyDataSource();

  final int seed;

  /// How many posts to generate. Zero is legal, and is how the feed's empty
  /// state gets exercised.
  final int postCount;
  final Random _random;
  final Faker _faker;
  final DateTime _now;

  late final List<User> users;
  late final List<Post> posts;
  late final List<UserStory> userStories;
  late final List<UserNotification> notifications;

  /// The signed-in user.
  User get currentUser => users.first;

  List<Post> postsBy(User user) {
    return posts.where((post) => post.owner.id == user.id).toList();
  }

  UserStory? storyFor(User user) {
    for (final UserStory story in userStories) {
      if (story.owner.id == user.id) return story;
    }
    return null;
  }

  /// A whole number of minutes in the past, so timestamps are ordered and
  /// reproducible rather than drawn at random from a range of years.
  DateTime _ago(int minutes) => _now.subtract(Duration(minutes: minutes));

  /// Picks an owner that guarantees coverage.
  ///
  /// While [index] is still within the user list the assignment is
  /// round-robin, so every user is used at least once. After that it is
  /// random over the *full* list — closing the off-by-one where
  /// `nextInt(users.length - 1)` could never return the last user.
  User _ownerFor(int index) {
    return index < users.length
        ? users[index]
        : users[_random.nextInt(users.length)];
  }

  /// Built here rather than with `faker.internet.userName()`.
  ///
  /// That method calls `List.shuffle()` with no argument, which uses its own
  /// unseeded `Random` — so it returns different results for the same Faker
  /// seed and would break determinism on its own.
  String _username() {
    final String first = _slug(_faker.person.firstName());
    final String last = _slug(_faker.person.lastName());
    final String separator = const ['_', '.', '-'][_random.nextInt(3)];

    return '$first$separator$last';
  }

  static String _slug(String value) {
    return value.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');
  }

  List<User> _generateUsers() {
    return List<User>.generate(_userCount, (index) {
      final String id = 'u${index + 1}';
      return User(
        id: id,
        isMe: index == 0,
        // A per-user picsum seed: distinct images, and the same image every
        // run. The previous `random: nextInt(5)` collided constantly.
        profileImage: _faker.image.loremPicsum(
          seed: 'avatar-$id',
          width: 320,
          height: 320,
        ),
        bannerImage: _faker.image.loremPicsum(
          seed: 'banner-$id',
          width: 960,
          height: 480,
        ),
        username: _username(),
        fullname: _faker.person.name(),
        bio: _faker.lorem.sentence(),
        followersCount: _random.nextInt(9000) + 100,
        followingCount: _random.nextInt(900) + 20,
      );
    });
  }

  List<Post> _generatePosts() {
    // Counts every comment generated so far, so coverage is guaranteed across
    // the whole corpus rather than per post.
    var commentIndex = 0;

    return List<Post>.generate(postCount, (index) {
      final String id = 'p${index + 1}';
      // Zero is allowed again: a post with no comments is realistic, and the
      // sheet has an empty state for it since T8. Before that it opened blank,
      // so the range was temporarily forced to start at one.
      final int commentCount = _random.nextInt(13);

      final List<Comment> comments = List<Comment>.generate(
        commentCount,
        (i) {
          final Comment comment = Comment(
            id: '$id-c${i + 1}',
            owner: _ownerFor(commentIndex),
            body: _faker.lorem.sentence(),
            likeCount: _random.nextInt(400),
            createdAt: _ago(index * 90 + (commentCount - i) * 7),
          );
          commentIndex++;
          return comment;
        },
      );

      return Post(
        id: id,
        owner: _ownerFor(index),
        postImage: _faker.image.loremPicsum(
          seed: 'post-$id',
          width: 960,
          height: 960,
        ),
        location: '${_faker.address.city()}, ${_faker.address.country()}',
        caption: _faker.lorem.sentence(),
        comments: comments,
        likeCount: _random.nextInt(5000),
        saveCount: _random.nextInt(900),
        // Newest first: post 1 is the most recent.
        createdAt: _ago(index * 90 + 5),
      );
    });
  }

  List<UserStory> _generateUserStories() {
    return List<UserStory>.generate(users.length, (index) {
      final User owner = users[index];
      final int storyCount = _random.nextInt(5) + 1;

      return UserStory(
        owner: owner,
        stories: List<Story>.generate(storyCount, (i) {
          final String id = '${owner.id}-s${i + 1}';
          return Story(
            id: id,
            storyImage: _faker.image.loremPicsum(
              seed: 'story-$id',
              width: 720,
              height: 1280,
            ),
            caption: _faker.lorem.sentence(),
            createdAt: _ago((storyCount - i) * 45 + index * 20),
          );
        }),
      );
    });
  }

  List<UserNotification> _generateNotifications() {
    const List<NotificationType> types = NotificationType.values;

    return List<UserNotification>.generate(_notificationCount, (index) {
      return UserNotification(
        id: 'n${index + 1}',
        // Round-robin over every type first, so `follow` is actually produced.
        // The previous `nextInt(2)` made that branch unreachable.
        type: index < types.length
            ? types[index]
            : types[_random.nextInt(types.length)],
        // Never the signed-in user: nobody is notified about themselves.
        actor: users[1 + _random.nextInt(users.length - 1)],
        createdAt: _ago(index * 137 + 12),
      );
    });
  }
}
