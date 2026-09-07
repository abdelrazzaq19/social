import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_social/common/common.dart';
import 'package:quick_social/models/models.dart';
import 'package:quick_social/repositories/repositories.dart';
import 'package:quick_social/theme/app_tokens.dart';
import 'package:quick_social/widgets/common/app_network_image.dart';
import 'package:quick_social/widgets/post_button.dart';

class CommentTile extends StatelessWidget {
  const CommentTile({
    super.key,
    required this.comment,
    this.onDelete,
  });

  final Comment comment;

  /// Shown only when the signed-in user wrote the comment.
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final CommentRepository comments = context.watch<CommentRepository>();
    final bool isLiked = comments.isLiked(comment.id);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppAvatar(
            url: comment.owner.profileImage,
            fallbackLabel: comment.owner.username,
            radius: 18,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: AppRadius.lgAll,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: comment.owner.username,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(
                          text: ' · ${timeAgo(comment.createdAt)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(comment.body, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      PostButton(
                        icon: Icon(
                          isLiked ? Icons.favorite : Icons.favorite_outline,
                          color: isLiked ? theme.colorScheme.primary : null,
                          size: 18,
                        ),
                        dense: true,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xs,
                          horizontal: AppSpacing.xs,
                        ),
                        tooltip: isLiked ? 'Unlike comment' : 'Like comment',
                        text: comments.likeCount(comment).toString(),
                        onTap: () => comments.toggleLike(comment.id),
                      ),
                      if (onDelete != null) ...[
                        const SizedBox(width: AppSpacing.sm),
                        // An icon rather than a labelled button: the row is a
                        // set of counts, and a stray "Delete" label reads as
                        // one of them.
                        IconButton(
                          onPressed: onDelete,
                          tooltip: 'Delete comment',
                          visualDensity: VisualDensity.compact,
                          iconSize: 18,
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
