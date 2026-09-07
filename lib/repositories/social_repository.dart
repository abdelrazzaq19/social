import 'package:flutter/foundation.dart';
import 'package:quick_social/models/models.dart';
import 'package:quick_social/services/prefs_service.dart';

/// Owns who the signed-in user follows.
class SocialRepository extends ChangeNotifier {
  SocialRepository(this._prefs)
      : _followedUserIds = _prefs.getStringList(_followedKey).toSet();

  static const String _followedKey = 'followedUserIds';

  final PrefsService _prefs;
  final Set<String> _followedUserIds;

  Set<String> get followedUserIds => Set.unmodifiable(_followedUserIds);

  bool isFollowing(String userId) => _followedUserIds.contains(userId);

  /// The follower count to display: the user's own count plus one if the
  /// signed-in user is following them.
  int followerCount(User user) {
    return user.followersCount + (isFollowing(user.id) ? 1 : 0);
  }

  Future<void> toggleFollow(String userId) async {
    if (!_followedUserIds.remove(userId)) _followedUserIds.add(userId);

    notifyListeners();
    await _prefs.setStringList(_followedKey, _followedUserIds.toList());
  }
}
