import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_social/common/common.dart';
import 'package:quick_social/data/dummy_data_source.dart';
import 'package:quick_social/models/models.dart';
import 'package:quick_social/repositories/repositories.dart';
import 'package:quick_social/theme/app_tokens.dart';
import 'package:quick_social/widgets/common/app_network_image.dart';
import 'package:quick_social/widgets/story/story_viewer.dart';

class UserStoryPage extends StatefulWidget {
  const UserStoryPage({
    super.key,
    required this.initialIndex,
    required this.userStories,
  });

  static MaterialPageRoute<void> route(
    int initialIndex, {
    List<UserStory>? userStories,
  }) {
    return MaterialPageRoute<void>(
      builder: (_) => UserStoryPage(
        initialIndex: initialIndex,
        userStories: userStories ?? DummyDataSource.instance.userStories,
      ),
    );
  }

  final int initialIndex;
  final List<UserStory> userStories;

  @override
  State<UserStoryPage> createState() => _UserStoryPageState();
}

class _UserStoryPageState extends State<UserStoryPage> {
  @override
  void initState() {
    super.initState();

    // After the first frame: marking seen notifies listeners, and doing that
    // while the tree is still building would rebuild widgets mid-build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markSeen(widget.initialIndex);
    });
  }

  void _markSeen(int pageIndex) {
    if (!mounted) return;
    if (pageIndex < 0 || pageIndex >= widget.userStories.length) return;

    context
        .read<StoryRepository>()
        .markSeen(widget.userStories[pageIndex].owner.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: StoryViewer(
        initialPage: widget.initialIndex,
        pageCount: widget.userStories.length,
        storyCountFor: (pageIndex) =>
            widget.userStories[pageIndex].stories.length,
        onPageChanged: _markSeen,
        onFinished: () => context.pop(),
        pageBuilder: (_, pageIndex, storyIndex) {
          return _storyImage(widget.userStories[pageIndex].stories[storyIndex]);
        },
        overlayBuilder: (context, pageIndex, storyIndex) {
          return _storyHeader(
            context,
            widget.userStories[pageIndex],
            widget.userStories[pageIndex].stories[storyIndex],
          );
        },
      ),
    );
  }

  Widget _storyImage(Story story) {
    return ColoredBox(
      color: Colors.black,
      child: Stack(
        children: [
          Positioned.fill(
            child: AppNetworkImage(
              url: story.storyImage,
              fit: BoxFit.contain,
              semanticLabel: story.caption,
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                ),
              ),
              child: Text(
                story.caption,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, height: 1.35),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _storyHeader(BuildContext context, UserStory userStory, Story story) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.paddingOf(context).top + AppSpacing.xxl,
          left: AppSpacing.lg,
          right: AppSpacing.sm,
          bottom: AppSpacing.md,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black87, Colors.transparent],
          ),
        ),
        child: Row(
          children: [
            AppAvatar(
              url: userStory.owner.profileImage,
              fallbackLabel: userStory.owner.username,
              radius: 18,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: userStory.owner.username,
                      style: textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    TextSpan(
                      text: '  ${timeAgo(story.createdAt)}',
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              onPressed: () => context.pop(),
              tooltip: 'Close',
              color: Colors.white,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }
}
