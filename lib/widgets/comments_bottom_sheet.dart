import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_social/data/dummy_data_source.dart';
import 'package:quick_social/models/models.dart';
import 'package:quick_social/repositories/repositories.dart';
import 'package:quick_social/theme/app_tokens.dart';
import 'package:quick_social/widgets/comment_tile.dart';
import 'package:quick_social/widgets/common/empty_state.dart';

class CommentsBottomSheet extends StatefulWidget {
  const CommentsBottomSheet({super.key, required this.post});

  static Future<void> showCommentsBottomSheet(
    BuildContext context, {
    required Post post,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      // The providers live above the navigator, and a modal route builds
      // outside this subtree — so hand the sheet the same values explicitly.
      builder: (_) => MultiProvider(
        providers: [
          ChangeNotifierProvider<CommentRepository>.value(
            value: context.read<CommentRepository>(),
          ),
        ],
        child: CommentsBottomSheet(post: post),
      ),
    );
  }

  final Post post;

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  /// Owned by the state, created once, and disposed.
  ///
  /// This used to be built inside `build()`: never disposed, and only
  /// *appearing* to clear on submit because the old controller was thrown
  /// away with the frame.
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final String text = _controller.text.trim();

    // Whitespace is not a comment.
    if (text.isEmpty) return;

    context.read<CommentRepository>().add(
          widget.post.id,
          Comment(
            id: '${widget.post.id}-c-local-'
                '${DateTime.now().microsecondsSinceEpoch}',
            owner: DummyDataSource.instance.currentUser,
            body: text,
            likeCount: 0,
            createdAt: DateTime.now(),
          ),
        );

    _controller.clear();
    _focusNode.unfocus();
  }

  Future<void> _confirmDelete(Comment comment) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete comment?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    context.read<CommentRepository>().delete(comment);
  }

  @override
  Widget build(BuildContext context) {
    final CommentRepository repository = context.watch<CommentRepository>();
    final List<Comment> comments = repository.commentsFor(widget.post);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Column(
          children: [
            _header(context, comments.length),
            Expanded(
              child: comments.isEmpty
                  ? _emptyState(scrollController)
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      itemCount: comments.length,
                      itemBuilder: (_, index) {
                        final Comment comment = comments[index];
                        return CommentTile(
                          comment: comment,
                          onDelete: repository.canDelete(comment)
                              ? () => _confirmDelete(comment)
                              : null,
                        );
                      },
                    ),
            ),
            _composer(context),
          ],
        );
      },
    );
  }

  Widget _header(BuildContext context, int count) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        count == 1 ? '1 comment' : '$count comments',
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  /// Scrollable even when empty, so the sheet still drags.
  Widget _emptyState(ScrollController scrollController) {
    return ListView(
      controller: scrollController,
      children: const [
        EmptyState(
          icon: Icons.mode_comment_outlined,
          title: 'No comments yet',
          message: 'Be the first to say something.',
        ),
      ],
    );
  }

  Widget _composer(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm + MediaQuery.viewInsetsOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _submit(),
              minLines: 1,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Add a comment',
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          IconButton(
            onPressed: _submit,
            tooltip: 'Post comment',
            icon: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}
