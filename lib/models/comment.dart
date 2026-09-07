import 'package:quick_social/models/models.dart';

class Comment {
  const Comment({
    required this.id,
    required this.owner,
    required this.body,
    required this.likeCount,
    required this.createdAt,
  });

  final String id;
  final User owner;
  final String body;
  final int likeCount;
  final DateTime createdAt;

  @override
  bool operator ==(Object other) {
    return identical(this, other) || (other is Comment && other.id == id);
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Comment($id, by @${owner.username})';
}
