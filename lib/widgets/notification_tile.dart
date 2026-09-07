import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_social/models/models.dart';
import 'package:quick_social/repositories/repositories.dart';

/// Marks the dot shown on an unread notification, so tests can count unread
/// tiles without reaching into the tile's internals.
const Key unreadDotKey = ValueKey('notification-unread-dot');

class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.notification,
  });

  final UserNotification notification;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final NotificationRepository repository =
        context.watch<NotificationRepository>();

    final bool isRead = repository.isRead(notification.id);
    final DateTime dateTime = notification.createdAt;

    return ListTile(
      onTap: () => repository.markRead(notification.id),
      leading: Icon(
        switch (notification.type) {
          NotificationType.like => Icons.favorite,
          NotificationType.comment => Icons.chat_bubble,
          NotificationType.follow => Icons.person_add,
        },
        color: isRead ? theme.disabledColor : theme.colorScheme.primary,
      ),
      title: Text(
        _message(notification),
        style: TextStyle(
          color: isRead ? theme.colorScheme.onSurface.withAlpha(150) : null,
        ),
      ),
      subtitle: Text(
        '${dateTime.day}/${dateTime.month}/${dateTime.year}',
        style: TextStyle(color: theme.disabledColor),
      ),
      trailing: isRead
          ? null
          : Container(
              key: unreadDotKey,
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
    );
  }

  /// Composed here rather than stored on the notification, so T16 can move
  /// these strings into ARB files without touching the data layer.
  String _message(UserNotification notification) {
    final String username = notification.actor.username;

    return switch (notification.type) {
      NotificationType.like => '$username liked your post',
      NotificationType.comment => '$username replied to your comment',
      NotificationType.follow => '$username started following you',
    };
  }
}
