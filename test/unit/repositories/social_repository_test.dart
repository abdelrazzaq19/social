import 'package:flutter_test/flutter_test.dart';
import 'package:quick_social/data/dummy_data_source.dart';
import 'package:quick_social/models/models.dart';
import 'package:quick_social/repositories/social_repository.dart';
import 'package:quick_social/services/prefs_service.dart';

import '../../helpers/test_prefs.dart';

void main() {
  late User user;

  setUp(() {
    user = DummyDataSource(now: DateTime.utc(2026, 9, 7)).users[1];
  });

  test('starts following nobody', () async {
    final repository = SocialRepository(await createTestPrefs());

    expect(repository.isFollowing(user.id), isFalse);
    expect(repository.followerCount(user), user.followersCount);
  });

  test('following adds one to the displayed follower count', () async {
    final repository = SocialRepository(await createTestPrefs());

    await repository.toggleFollow(user.id);

    expect(repository.isFollowing(user.id), isTrue);
    expect(repository.followerCount(user), user.followersCount + 1);
  });

  test('unfollowing puts the count back', () async {
    final repository = SocialRepository(await createTestPrefs());

    await repository.toggleFollow(user.id);
    await repository.toggleFollow(user.id);

    expect(repository.isFollowing(user.id), isFalse);
    expect(repository.followerCount(user), user.followersCount);
  });

  test('notifies listeners', () async {
    final repository = SocialRepository(await createTestPrefs());
    var notifications = 0;
    repository.addListener(() => notifications++);

    await repository.toggleFollow(user.id);

    expect(notifications, 1);
  });

  test('survives a restart', () async {
    final PrefsService prefs = await createTestPrefs();
    await SocialRepository(prefs).toggleFollow(user.id);

    expect(SocialRepository(prefs).isFollowing(user.id), isTrue);
  });

  test('tracks each user independently', () async {
    final source = DummyDataSource(now: DateTime.utc(2026, 9, 7));
    final repository = SocialRepository(await createTestPrefs());

    await repository.toggleFollow(source.users[1].id);

    expect(repository.isFollowing(source.users[1].id), isTrue);
    expect(repository.isFollowing(source.users[2].id), isFalse);
  });
}
