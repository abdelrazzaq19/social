import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_social/common/common.dart';
import 'package:quick_social/models/models.dart';
import 'package:quick_social/pages/pages.dart';
import 'package:quick_social/repositories/repositories.dart';
import 'package:quick_social/theme/app_tokens.dart';
import 'package:quick_social/widgets/widgets.dart';
import 'package:share_plus/share_plus.dart';

class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.post,
  });

  final Post post;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: context.responsive<Widget>(
        sm: _mobileCard(context),
        md: _wideCard(context),
      ),
    );
  }

  Widget _mobileCard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _header(context),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            0,
          ),
          child: Text(post.caption),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.lg,
          ),
          child: _PostImage(post: post),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: _postButtons(context),
        ),
      ],
    );
  }

  /// Tablet and desktop.
  ///
  /// The image and the text sit side by side. Both columns are sized by their
  /// own content — the previous version wrapped them in `IntrinsicHeight`,
  /// which handed the action row a width unrelated to the space available and
  /// overflowed it at every width from 768 to 1024 (E21).
  Widget _wideCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _PostImage(post: post)),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _header(context, contentPadding: EdgeInsets.zero),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.md,
                  ),
                  child: Text(post.caption),
                ),
                _postButtons(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, {EdgeInsets? contentPadding}) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return ListTile(
      onTap: () => context.push(route: ProfilePage.route(post.owner)),
      contentPadding: contentPadding,
      leading: AppAvatar(
        url: post.owner.profileImage,
        fallbackLabel: post.owner.username,
      ),
      // One `Text.rich` rather than a `Row`: a row of two texts needs both to
      // be flexible or the second one overflows a narrow column, which is
      // exactly how E21 showed up here.
      title: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: post.owner.username,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(
              text: ' · ${timeAgo(post.createdAt)}',
              style: textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        post.location,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: textTheme.bodySmall,
      ),
      trailing: IconButton(
        onPressed: () => _showPostMenu(context),
        tooltip: 'More options',
        icon: const Icon(Icons.more_vert),
      ),
    );
  }

  Widget _postButtons(BuildContext context) {
    final FeedRepository feed = context.watch<FeedRepository>();

    return Row(
      children: [
        Expanded(
          child: _ToggleButton(
            isActive: feed.isLiked(post.id),
            count: feed.likeCount(post),
            iconData: Icons.favorite_outline,
            activeIconData: Icons.favorite,
            tooltip: feed.isLiked(post.id) ? 'Unlike' : 'Like',
            onTap: () => feed.toggleLike(post.id),
          ),
        ),
        Expanded(child: _CommentButton(post: post)),
        Expanded(
          child: _ToggleButton(
            isActive: feed.isSaved(post.id),
            count: feed.saveCount(post),
            iconData: Icons.bookmark_outline,
            activeIconData: Icons.bookmark,
            tooltip: feed.isSaved(post.id) ? 'Remove from saved' : 'Save',
            onTap: () => feed.toggleSave(post.id),
          ),
        ),
        IconButton(
          onPressed: () => _share(context),
          tooltip: 'Share',
          icon: const Icon(Icons.ios_share),
        ),
      ],
    );
  }

  Future<void> _share(BuildContext context) async {
    final Rect origin = _shareOrigin(context);

    await SharePlus.instance.share(
      ShareParams(
        text: '${post.owner.username} on Quick Social: ${post.caption}',
        subject: 'A post from ${post.owner.username}',
        // iPad needs an anchor for the share popover, or it throws.
        sharePositionOrigin: origin,
      ),
    );
  }

  Rect _shareOrigin(BuildContext context) {
    final RenderObject? box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return Rect.zero;

    return box.localToGlobal(Offset.zero) & box.size;
  }

  void _showPostMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text('View @${post.owner.username}'),
                onTap: () {
                  sheetContext.pop();
                  context.push(route: ProfilePage.route(post.owner));
                },
              ),
              ListTile(
                leading: const Icon(Icons.ios_share),
                title: const Text('Share'),
                onTap: () {
                  sheetContext.pop();
                  _share(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

/// The post's image, with double-tap-to-like.
class _PostImage extends StatefulWidget {
  const _PostImage({required this.post});

  final Post post;

  @override
  State<_PostImage> createState() => _PostImageState();
}

class _PostImageState extends State<_PostImage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _burstController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void dispose() {
    _burstController.dispose();
    super.dispose();
  }

  void _onDoubleTap() {
    final FeedRepository feed = context.read<FeedRepository>();

    // Double-tap likes; it never unlikes. Undoing is what the button is for.
    if (!feed.isLiked(widget.post.id)) feed.toggleLike(widget.post.id);

    _burstController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: _onDoubleTap,
      child: ClipRRect(
        borderRadius: AppRadius.mdAll,
        child: AspectRatio(
          // Fixed, so the card occupies its final height before the image
          // arrives and nothing below it jumps.
          aspectRatio: 1,
          child: Stack(
            fit: StackFit.expand,
            children: [
              AppNetworkImage(
                url: widget.post.postImage,
                semanticLabel: 'Post by ${widget.post.owner.username}',
              ),
              // Never absorbs a tap: it sits over the image, so without this
              // the second double-tap lands on the heart instead.
              IgnorePointer(child: Center(child: _burst())),
            ],
          ),
        ),
      ),
    );
  }

  Widget _burst() {
    return AnimatedBuilder(
      animation: _burstController,
      builder: (_, __) {
        final double t = _burstController.value;
        if (t == 0) return const SizedBox.shrink();

        // Pops out, holds, fades.
        final double scale = t < 0.3 ? 0.6 + (t / 0.3) * 0.6 : 1.2 - t * 0.2;
        final double opacity = t < 0.6 ? 1 : (1 - t) / 0.4;

        return Opacity(
          opacity: opacity.clamp(0, 1),
          child: Transform.scale(
            scale: scale,
            child: const Icon(
              Icons.favorite,
              size: 96,
              color: Colors.white,
              shadows: [Shadow(blurRadius: 24, color: Colors.black54)],
            ),
          ),
        );
      },
    );
  }
}

/// Stateless: the count comes from `CommentRepository`, so it updates while
/// the sheet is open rather than only after it closes.
class _CommentButton extends StatelessWidget {
  const _CommentButton({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final CommentRepository comments = context.watch<CommentRepository>();

    return PostButton(
      icon: const Icon(Icons.chat_bubble_outline),
      text: comments.countFor(post).toString(),
      tooltip: 'Comments',
      onTap: () => CommentsBottomSheet.showCommentsBottomSheet(
        context,
        post: post,
      ),
    );
  }
}

/// Like and Save.
///
/// Stateless on purpose: it used to keep its own `bool` and its own count, so
/// a like vanished the moment the widget was disposed and never reached the
/// rest of the app. Both now come from `FeedRepository`.
class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
    required this.count,
    required this.iconData,
    required this.activeIconData,
    required this.isActive,
    required this.tooltip,
    required this.onTap,
  });

  final IconData iconData;
  final IconData activeIconData;
  final int count;
  final bool isActive;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return PostButton(
      icon: Icon(
        isActive ? activeIconData : iconData,
        color: isActive ? theme.colorScheme.primary : null,
      ),
      text: count.toString(),
      tooltip: tooltip,
      onTap: onTap,
    );
  }
}
