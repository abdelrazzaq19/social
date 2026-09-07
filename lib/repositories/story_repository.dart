import 'package:flutter/foundation.dart';
import 'package:quick_social/models/models.dart';
import 'package:quick_social/services/prefs_service.dart';

/// Remembers whose stories have been watched.
///
/// Seen state is tracked per owner rather than per individual story: the ring
/// in the feed is about a person, and dimming it the moment their set is
/// opened is what the affordance actually means.
class StoryRepository extends ChangeNotifier {
  StoryRepository(this._prefs)
      : _seenOwnerIds = _prefs.getStringList(_seenKey).toSet();

  static const String _seenKey = 'seenStoryOwnerIds';

  final PrefsService _prefs;
  final Set<String> _seenOwnerIds;

  bool hasUnseen(UserStory story) => !_seenOwnerIds.contains(story.owner.id);

  Future<void> markSeen(String ownerId) async {
    if (!_seenOwnerIds.add(ownerId)) return;

    notifyListeners();
    await _prefs.setStringList(_seenKey, _seenOwnerIds.toList());
  }

  /// Puts the signed-in user first, then anyone with unseen stories, then the
  /// rest — the order a story rail is expected to be in.
  List<UserStory> ordered(List<UserStory> stories) {
    final List<UserStory> sorted = [...stories];

    sorted.sort((a, b) {
      if (a.owner.isMe != b.owner.isMe) return a.owner.isMe ? -1 : 1;

      final bool aUnseen = hasUnseen(a);
      final bool bUnseen = hasUnseen(b);
      if (aUnseen != bUnseen) return aUnseen ? -1 : 1;

      return b.latest.createdAt.compareTo(a.latest.createdAt);
    });

    return sorted;
  }
}
