class Story {
  const Story({
    required this.id,
    required this.storyImage,
    required this.caption,
    required this.createdAt,
  });

  final String id;
  final String storyImage;
  final String caption;
  final DateTime createdAt;

  @override
  bool operator ==(Object other) {
    return identical(this, other) || (other is Story && other.id == id);
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Story($id)';
}
