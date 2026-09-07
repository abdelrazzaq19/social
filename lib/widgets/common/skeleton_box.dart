import 'package:flutter/material.dart';
import 'package:quick_social/theme/app_tokens.dart';

/// A neutral block standing in for content that has not arrived yet.
///
/// Deliberately still. A pulsing shimmer would be an animation that never
/// ends, which makes `pumpAndSettle` hang in every test that renders a loading
/// state — T20 owns motion and can add one behind a reduced-motion check.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height = 12,
    this.borderRadius = AppRadius.smAll,
    this.shape = BoxShape.rectangle,
  });

  /// A circle of [size], for avatars.
  const SkeletonBox.circle({super.key, required double size})
      : width = size,
        height = size,
        borderRadius = null,
        shape = BoxShape.circle;

  final double? width;
  final double height;
  final BorderRadius? borderRadius;
  final BoxShape shape;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: shape == BoxShape.circle ? null : borderRadius,
        shape: shape,
      ),
    );
  }
}
