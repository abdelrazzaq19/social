import 'package:flutter_test/flutter_test.dart';
import 'package:quick_social/data/dummy_data_source.dart';
import 'package:quick_social/models/models.dart';
import 'package:quick_social/repositories/notification_repository.dart';
import 'package:quick_social/services/prefs_service.dart';

import '../../helpers/test_prefs.dart';

void main() {
  late List<UserNotification> notifications;

  setUp(() {
    notifications =
        DummyDataSource(now: DateTime.utc(2026, 9, 7)).notifications;
  });

  test('everything starts unread', () async {
    final repository = NotificationRepository(await createTestPrefs());

    expect(repository.unreadCount(notifications), notifications.length);
    expect(repository.hasUnread(notifications), isTrue);
  });

  test('marking one read leaves the rest alone', () async {
    final repository = NotificationRepository(await createTestPrefs());

    await repository.markRead(notifications.first.id);

    expect(repository.isRead(notifications.first.id), isTrue);
    expect(repository.isRead(notifications[1].id), isFalse);
    expect(repository.unreadCount(notifications), notifications.length - 1);
  });

  test('marking the same one twice notifies only once', () async {
    final repository = NotificationRepository(await createTestPrefs());
    var count = 0;
    repository.addListener(() => count++);

    await repository.markRead(notifications.first.id);
    await repository.markRead(notifications.first.id);

    expect(count, 1);
  });

  test('mark all read clears the unread count', () async {
    final repository = NotificationRepository(await createTestPrefs());

    await repository.markAllRead(notifications);

    expect(repository.unreadCount(notifications), 0);
    expect(repository.hasUnread(notifications), isFalse);
  });

  test('mark all read on an already-read list is inert', () async {
    final repository = NotificationRepository(await createTestPrefs());
    await repository.markAllRead(notifications);

    var count = 0;
    repository.addListener(() => count++);
    await repository.markAllRead(notifications);

    expect(count, 0);
  });

  test('survives a restart — E8', () async {
    final PrefsService prefs = await createTestPrefs();
    await NotificationRepository(prefs).markRead(notifications.first.id);

    final reopened = NotificationRepository(prefs);

    expect(reopened.isRead(notifications.first.id), isTrue);
    expect(reopened.unreadCount(notifications), notifications.length - 1);
  });
}
