import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:quick_social/widgets/error_image_widget.dart';
import 'package:quick_social/widgets/loading_image_widget.dart';

/// Every remote image in the app goes through here.
///
/// One place decides how an image loads, what it shows while loading, and what
/// it shows when loading fails. Before this, most images were a bare
/// `Image.network` with no `errorBuilder`, so a slow or unreachable host left
/// blank rectangles and threw exceptions into the console.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.semanticLabel,
  });

  /// Substitutes the image provider, for tests.
  ///
  /// `CachedNetworkImage` reaches the file system through `path_provider`,
  /// which has no implementation under `flutter_test` — so a widget test that
  /// renders an image would throw `MissingPluginException`. Tests set this to
  /// an in-memory provider instead. Null in production.
  @visibleForTesting
  static ImageProvider Function(String url)? debugProviderOverride;

  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final Widget image = _image();

    if (borderRadius == null) return image;

    return ClipRRect(borderRadius: borderRadius!, child: image);
  }

  Widget _image() {
    final ImageProvider Function(String url)? override = debugProviderOverride;

    if (override != null) {
      return Image(
        image: override(url),
        fit: fit,
        width: width,
        height: height,
        semanticLabel: semanticLabel,
        errorBuilder: (_, __, ___) => const ErrorImageWidget(),
      );
    }

    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      width: width,
      height: height,
      placeholder: (_, __) => const LoadingImageWidget(),
      errorWidget: (_, __, ___) => const ErrorImageWidget(),
      // Cross-fade the loaded image in, so a cached image does not flash a
      // placeholder and a slow one does not snap.
      fadeInDuration: const Duration(milliseconds: 200),
      imageBuilder: semanticLabel == null
          ? null
          : (context, imageProvider) => Semantics(
                label: semanticLabel,
                image: true,
                child: Image(image: imageProvider, fit: fit),
              ),
    );
  }
}

/// A circular avatar backed by [AppNetworkImage].
///
/// `CircleAvatar(backgroundImage: NetworkImage(...))` has no error path at
/// all: a failed load leaves a coloured disc with no indication anything went
/// wrong. This falls back to the owner's initial instead.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.url,
    required this.fallbackLabel,
    this.radius = 20,
  });

  final String url;

  /// Used for the fallback initial and the semantic label.
  final String fallbackLabel;

  final double radius;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Semantics(
      label: fallbackLabel,
      image: true,
      child: ClipOval(
        child: Container(
          width: radius * 2,
          height: radius * 2,
          color: scheme.surfaceContainerHighest,
          alignment: Alignment.center,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: Text(
                  _initial,
                  style: TextStyle(
                    fontSize: radius * 0.9,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              AppNetworkImage(url: url, fit: BoxFit.cover),
            ],
          ),
        ),
      ),
    );
  }

  String get _initial {
    final String trimmed = fallbackLabel.trim();
    return trimmed.isEmpty ? '?' : trimmed.characters.first.toUpperCase();
  }
}
