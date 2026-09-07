import 'package:flutter/material.dart';
import 'package:quick_social/widgets/common/skeleton_box.dart';

/// Shown in place of an image that is still downloading.
///
/// A neutral block rather than a spinner: it reads as "content is coming"
/// instead of "something is wrong", it does not draw the eye to every image on
/// a long feed, and — unlike an indeterminate progress indicator — it does not
/// animate forever, which used to make `pumpAndSettle` hang in any test that
/// rendered the feed.
class LoadingImageWidget extends StatelessWidget {
  const LoadingImageWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const SkeletonBox(
      height: double.infinity,
      borderRadius: BorderRadius.zero,
    );
  }
}
