import 'package:flutter/foundation.dart';
import 'package:quick_social/models/models.dart';
import 'package:quick_social/services/prefs_service.dart';

/// Owns which notifications have been read.
///
/// Read state used to be duplicated: the page held a list while each tile kept
/// its own copy, and both were derived from a mutable global. Tapping a tile
/// was silently lost on the next rebuild. One set of ids, in one place, fixes
/// that and survives a restart.
class NotificationRepository extends ChangeNotifier {
  NotificationRepository(this._prefs)
      : _readIds = _prefs.getStringList(_readKey).toSet();

  static const String _readKey = 'readNotificationIds';

  final PrefsService _prefs;
  final Set<String> _readIds;

  bool isRead(String notificationId) => _readIds.contains(notificationId);

  int unreadCount(Iterable<UserNotification> notifications) {
    return notifications.where((n) => !isRead(n.id)).length;
  }

  bool hasUnread(Iterable<UserNotification> notifications) {
    return notifications.any((n) => !isRead(n.id));
  }

  Future<void> markRead(String notificationId) async {
    if (!_readIds.add(notificationId)) return;

    notifyListeners();
    await _persist();
  }

  Future<void> markAllRead(Iterable<UserNotification> notifications) async {
    final Iterable<String> ids = notifications.map((n) => n.id);
    final int before = _readIds.length;
    _readIds.addAll(ids);
    if (_readIds.length == before) return;

    notifyListeners();
    await _persist();
  }

  Future<void> _persist() => _prefs.setStringList(_readKey, _readIds.toList());
}
