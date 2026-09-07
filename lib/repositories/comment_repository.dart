import 'package:flutter/foundation.dart';
import 'package:quick_social/models/models.dart';
import 'package:quick_social/services/prefs_service.dart';

/// Owns everything the signed-in user does to comments: which ones they have
/// liked, which they have written, and which of their own they have deleted.
///
/// The seed comments on [Post] stay immutable. Previously the sheet appended
/// straight into `post.comments`, mutating shared app data from a widget —
/// which is why the count on the card and the contents of the sheet could
/// disagree.
///
/// Likes persist. Written and deleted comments live for the session only;
/// persisting user-authored content is T14's job, and it needs serialisation
/// this class deliberately does not invent yet.
class CommentRepository extends ChangeNotifier {
  CommentRepository(this._prefs)
      : _likedCommentIds = _prefs.getStringList(_likedKey).toSet();

  static const String _likedKey = 'likedCommentIds';

  final PrefsService _prefs;

  final Set<String> _likedCommentIds;
  final Map<String, List<Comment>> _addedByPostId = {};
  final Set<String> _deletedCommentIds = {};

  /// The comments to show for [post]: the seeded ones, minus anything the user
  /// deleted, plus anything they wrote.
  List<Comment> commentsFor(Post post) {
    return [
      ...post.comments.where((c) => !_deletedCommentIds.contains(c.id)),
      ...?_addedByPostId[post.id],
    ];
  }

  int countFor(Post post) => commentsFor(post).length;

  bool isLiked(String commentId) => _likedCommentIds.contains(commentId);

  /// The count to display: the comment's own, plus the user's own like.
  int likeCount(Comment comment) {
    return comment.likeCount + (isLiked(comment.id) ? 1 : 0);
  }

  /// True when the user wrote this comment, and so may delete it.
  bool canDelete(Comment comment) => comment.owner.isMe;

  Future<void> toggleLike(String commentId) async {
    if (!_likedCommentIds.remove(commentId)) _likedCommentIds.add(commentId);

    notifyListeners();
    await _prefs.setStringList(_likedKey, _likedCommentIds.toList());
  }

  void add(String postId, Comment comment) {
    _addedByPostId.putIfAbsent(postId, () => []).add(comment);
    notifyListeners();
  }

  void delete(Comment comment) {
    _deletedCommentIds.add(comment.id);

    for (final List<Comment> added in _addedByPostId.values) {
      added.removeWhere((c) => c.id == comment.id);
    }

    notifyListeners();
  }
}
