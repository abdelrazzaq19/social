import 'package:flutter/foundation.dart';
import 'package:quick_social/models/models.dart';
import 'package:quick_social/services/prefs_service.dart';

/// Owns which posts the signed-in user has liked and saved.
///
/// Before this existed, that state lived in the `State` of the button widget
/// itself, so it reset whenever the widget was disposed — a tab switch was
/// enough to un-like a post — and it never reached the model, so the same post
/// could show different counts in the feed and on a profile.
///
/// The counts on [Post] are treated as everyone *else's*: the signed-in user's
/// own like adds one on top. That keeps the seed data immutable.
class FeedRepository extends ChangeNotifier {
  FeedRepository(this._prefs)
      : _likedPostIds = _prefs.getStringList(_likedKey).toSet(),
        _savedPostIds = _prefs.getStringList(_savedKey).toSet();

  static const String _likedKey = 'likedPostIds';
  static const String _savedKey = 'savedPostIds';

  final PrefsService _prefs;

  final Set<String> _likedPostIds;
  final Set<String> _savedPostIds;

  /// Saved posts, most recently saved last. Read by the saved-posts page.
  Set<String> get savedPostIds => Set.unmodifiable(_savedPostIds);

  bool isLiked(String postId) => _likedPostIds.contains(postId);

  bool isSaved(String postId) => _savedPostIds.contains(postId);

  /// The count to display: the post's own count plus the user's own like.
  int likeCount(Post post) => post.likeCount + (isLiked(post.id) ? 1 : 0);

  int saveCount(Post post) => post.saveCount + (isSaved(post.id) ? 1 : 0);

  Future<void> toggleLike(String postId) {
    return _toggle(_likedPostIds, postId, _likedKey);
  }

  Future<void> toggleSave(String postId) {
    return _toggle(_savedPostIds, postId, _savedKey);
  }

  Future<void> _toggle(Set<String> ids, String id, String key) async {
    if (!ids.remove(id)) ids.add(id);

    notifyListeners();
    await _prefs.setStringList(key, ids.toList());
  }
}
