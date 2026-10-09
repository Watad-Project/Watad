import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_image_placeholder.dart';

/// An image from a URL (e.g. a Supabase Storage URL). The striped
/// placeholder shows while it loads, when it fails, and when [url] is empty.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.semanticLabel,
  });

  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  /// What screen readers say. Without it the image is treated as decoration.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final source = url;
    final Widget image = source == null || source.isEmpty
        ? const AppImagePlaceholder()
        : Image.network(
            source,
            fit: fit,
            width: width,
            height: height,
            semanticLabel: semanticLabel,
            excludeFromSemantics: semanticLabel == null,
            // Until the first frame is decoded there is nothing to show.
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) =>
                frame == null ? const AppImagePlaceholder() : child,
            errorBuilder: (context, error, stackTrace) =>
                const AppImagePlaceholder(),
          );
    return SizedBox(
      width: width,
      height: height,
      child: borderRadius == null
          ? image
          : ClipRRect(borderRadius: borderRadius!, child: image),
    );
  }
}
