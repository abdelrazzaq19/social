import 'package:flutter/material.dart';
import 'package:quick_social/theme/app_tokens.dart';
import 'package:quick_social/widgets/common/skeleton_box.dart';

/// A placeholder shaped like a loaded post.
///
/// The footprint matters as much as the look: if the placeholder is a
/// different height from the real card, the list jumps when content arrives.
class PostSkeleton extends StatelessWidget {
  const PostSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SkeletonBox.circle(size: 40),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonBox(width: 120, height: 14),
                  SizedBox(height: AppSpacing.sm),
                  SkeletonBox(width: 80, height: 10),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const SkeletonBox(height: 12),
          const SizedBox(height: AppSpacing.sm),
          const SkeletonBox(width: 200, height: 12),
          const SizedBox(height: AppSpacing.lg),
          const AspectRatio(
            aspectRatio: 1,
            child: SkeletonBox(
              height: double.infinity,
              borderRadius: AppRadius.mdAll,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: const [
              SkeletonBox(width: 56, height: 16),
              SkeletonBox(width: 56, height: 16),
              SkeletonBox(width: 56, height: 16),
            ],
          ),
        ],
      ),
    );
  }
}

/// The story row's placeholder.
class StoryRailSkeleton extends StatelessWidget {
  const StoryRailSkeleton({super.key, this.count = 5});

  final int count;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.storyRail,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: count,
        itemBuilder: (_, __) {
          return const Padding(
            padding: EdgeInsets.only(right: AppSpacing.lg),
            child: Column(
              children: [
                SizedBox(height: AppSpacing.sm),
                SkeletonBox.circle(size: AppSizes.storyAvatar),
                SizedBox(height: AppSpacing.sm),
                SkeletonBox(width: 48, height: 10),
              ],
            ),
          );
        },
      ),
    );
  }
}
