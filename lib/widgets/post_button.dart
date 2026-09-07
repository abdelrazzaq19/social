import 'package:flutter/material.dart';
import 'package:quick_social/theme/app_tokens.dart';

/// One action under a post: an icon, a count, and a tap target.
class PostButton extends StatelessWidget {
  const PostButton({
    super.key,
    required this.icon,
    required this.text,
    required this.onTap,
    required this.tooltip,
    this.padding,
    this.dense = false,
  });

  final Icon icon;
  final String text;
  final VoidCallback onTap;

  /// Also the semantic label — the icon alone does not say what it does.
  final String tooltip;

  final EdgeInsets? padding;

  /// Smaller, for use inside a comment rather than under a post.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.smAll,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: dense ? 0 : AppSizes.minTapTarget,
          ),
          child: Padding(
            padding: padding ??
                const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                icon,
                const SizedBox(width: AppSpacing.xs),
                // Flexible with an ellipsis: a wide count in a narrow slot
                // must shrink, not overflow. Without this the row overflowed
                // on small phones and across the whole tablet range (E21).
                Flexible(
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
