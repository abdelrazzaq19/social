import 'package:flutter/material.dart';
import 'package:story/story_page_view.dart';

/// The single point of contact with `package:story`.
///
/// That package is small and infrequently updated, and it sits on the critical
/// path of a whole feature. Keeping every reference to it behind this widget
/// means a breaking change — or swapping it for a hand-rolled viewer — is a
/// one-file job rather than a hunt through the app.
///
/// Nothing outside this file should import `package:story`.
class StoryViewer extends StatelessWidget {
  const StoryViewer({
    super.key,
    required this.pageCount,
    required this.storyCountFor,
    required this.initialPage,
    required this.pageBuilder,
    required this.overlayBuilder,
    required this.onPageChanged,
    required this.onFinished,
  });

  /// How many owners are in this run of stories.
  final int pageCount;

  /// How many stories the owner at a given page has.
  final int Function(int pageIndex) storyCountFor;

  final int initialPage;

  /// Builds the story itself.
  final Widget Function(BuildContext context, int pageIndex, int storyIndex)
      pageBuilder;

  /// Builds anything drawn over the story that should stay interactive —
  /// the header, the close button.
  final Widget Function(BuildContext context, int pageIndex, int storyIndex)
      overlayBuilder;

  /// Called when the viewer moves to a different owner.
  final ValueChanged<int> onPageChanged;

  /// Called when the last story of the last owner finishes.
  final VoidCallback onFinished;

  @override
  Widget build(BuildContext context) {
    return StoryPageView(
      initialPage: initialPage,
      pageLength: pageCount,
      storyLength: storyCountFor,
      itemBuilder: pageBuilder,
      gestureItemBuilder: overlayBuilder,
      onPageChanged: onPageChanged,
      onPageLimitReached: onFinished,
      backgroundColor: Theme.of(context).colorScheme.scrim,
      indicatorDuration: const Duration(seconds: 5),
    );
  }
}
