import 'package:quick_social/models/models.dart';

class Post {
  const Post({
    required this.id,
    required this.owner,
    required this.postImage,
    required this.location,
    required this.caption,
    required this.comments,
    required this.likeCount,
    required this.saveCount,
    required this.createdAt,
  });

  final String id;
  final User owner;
  final String postImage;
  final String location;
  final String caption;
  final List<Comment> comments;
  final int likeCount;
  final int saveCount;
  final DateTime createdAt;

  /// Whether the signed-in user has liked or saved a post is **not** on the
  /// model: it lives in `FeedRepository`, so there is one answer everywhere
  /// the post appears. The counts here are everyone else's.
  Post copyWith({
    List<Comment>? comments,
    int? likeCount,
    int? saveCount,
  }) {
    return Post(
      id: id,
      owner: owner,
      postImage: postImage,
      location: location,
      caption: caption,
      comments: comments ?? this.comments,
      likeCount: likeCount ?? this.likeCount,
      saveCount: saveCount ?? this.saveCount,
      createdAt: createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) || (other is Post && other.id == id);
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Post($id, by @${owner.username})';
}
