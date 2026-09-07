import 'package:quick_social/models/models.dart';

class UserStory {
  const UserStory({
    required this.owner,
    required this.stories,
  });

  final User owner;
  final List<Story> stories;

  /// The most recent story, which is what the ring in the feed represents.
  Story get latest => stories.last;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UserStory && other.owner.id == owner.id);
  }

  @override
  int get hashCode => owner.id.hashCode;

  @override
  String toString() => 'UserStory(@${owner.username}, ${stories.length})';
}
