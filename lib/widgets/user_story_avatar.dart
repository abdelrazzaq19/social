import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_social/models/models.dart';
import 'package:quick_social/repositories/repositories.dart';
import 'package:quick_social/theme/app_tokens.dart';
import 'package:quick_social/widgets/common/app_network_image.dart';

/// An avatar wrapped in a story ring.
///
/// The ring is the whole affordance: a gradient means there is something new
/// to watch, a flat outline means you have already seen it. Before this the
/// ring was a `CircularProgressIndicator` with a fixed value, which looked the
/// same either way and said nothing.
class UserStoryAvatar extends StatelessWidget {
  const UserStoryAvatar({
    super.key,
    required this.userStory,
    required this.onTap,
    this.radius = AppSizes.storyAvatar / 2,
    this.showAddBadge = false,
  });

  final UserStory userStory;
  final VoidCallback onTap;
  final double radius;

  /// Draws the "add to your story" badge. Decorative for now — tapping the
  /// tile opens the story; T14 routes this to the compose flow.
  final bool showAddBadge;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool hasUnseen = context.watch<StoryRepository>().hasUnseen(
          userStory,
        );

    const double ringWidth = 2.5;
    const double gap = 2;
    final double outerSize = (radius + ringWidth + gap) * 2;

    return Semantics(
      button: true,
      label: hasUnseen
          ? 'Unseen story from ${userStory.owner.username}'
          : 'Story from ${userStory.owner.username}',
      child: SizedBox(
        width: outerSize,
        height: outerSize,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: outerSize,
              height: outerSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: hasUnseen ? _ringGradient(scheme) : null,
                color: hasUnseen ? null : scheme.outlineVariant,
              ),
              child: Padding(
                padding: const EdgeInsets.all(ringWidth),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.surface,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(gap),
                    child: AppAvatar(
                      url: userStory.owner.profileImage,
                      fallbackLabel: userStory.owner.username,
                      radius: radius,
                    ),
                  ),
                ),
              ),
            ),
            if (showAddBadge)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.primary,
                    border: Border.all(color: scheme.surface, width: 2),
                  ),
                  child: Icon(
                    Icons.add,
                    size: 12,
                    color: scheme.onPrimary,
                  ),
                ),
              ),
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(onTap: onTap),
              ),
            ),
          ],
        ),
      ),
    );
  }

  LinearGradient _ringGradient(ColorScheme scheme) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        scheme.primary,
        scheme.tertiary,
        scheme.primary,
      ],
    );
  }
}
