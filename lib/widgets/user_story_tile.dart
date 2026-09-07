import 'package:flutter/material.dart';
import 'package:quick_social/common/common.dart';
import 'package:quick_social/models/models.dart';
import 'package:quick_social/pages/user_story_page.dart';
import 'package:quick_social/theme/app_tokens.dart';
import 'package:quick_social/widgets/user_story_avatar.dart';

/// One entry in the story rail.
class UserStoryTile extends StatelessWidget {
  const UserStoryTile({
    super.key,
    required this.userStory,
    required this.stories,
    required this.index,
  });

  final UserStory userStory;

  /// The full run the viewer can page through, so swiping sideways inside the
  /// viewer moves between owners.
  final List<UserStory> stories;

  /// Where this owner sits in [stories].
  final int index;

  bool get _isMine => userStory.owner.isMe;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.sm),
          UserStoryAvatar(
            userStory: userStory,
            showAddBadge: _isMine,
            onTap: () => context.push(
              route: UserStoryPage.route(index, userStories: stories),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            width: 72,
            child: Text(
              _isMine ? 'Your story' : userStory.owner.username,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelSmall?.copyWith(
                fontWeight: _isMine ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
