import 'package:quick_social/models/models.dart';

enum NotificationType { like, comment, follow }

class UserNotification {
  const UserNotification({
    required this.id,
    required this.type,
    required this.actor,
    required this.createdAt,
  });

  final String id;
  final NotificationType type;

  /// Who did the thing.
  ///
  /// The notification stores the actor rather than a pre-built sentence, so
  /// the wording lives in the widget layer where it can be localized.
  final User actor;

  final DateTime createdAt;

  /// Whether it has been read is **not** on the model: it lives in
  /// `NotificationRepository`, so the page and the tile cannot disagree.

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UserNotification && other.id == id);
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'UserNotification($id, ${type.name})';
}
