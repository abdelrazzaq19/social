class User {
  const User({
    required this.id,
    required this.profileImage,
    required this.bannerImage,
    required this.username,
    required this.fullname,
    required this.bio,
    required this.followersCount,
    required this.followingCount,
    this.isMe = false,
  });

  /// Stable across runs, so it can key persisted state and appear in a URL.
  final String id;

  final String profileImage;
  final String bannerImage;
  final String username;
  final String fullname;
  final String bio;
  final int followersCount;
  final int followingCount;
  final bool isMe;

  User copyWith({
    int? followersCount,
    int? followingCount,
  }) {
    return User(
      id: id,
      profileImage: profileImage,
      bannerImage: bannerImage,
      username: username,
      fullname: fullname,
      bio: bio,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      isMe: isMe,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) || (other is User && other.id == id);
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'User($id, @$username)';
}
