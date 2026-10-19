import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_image_placeholder.dart';
import 'package:watad/core/components/feedback/app_shimmer.dart';

/// An image from a URL (e.g. a Supabase Storage URL). A shimmer shows while
/// it loads; the striped placeholder when it fails or [url] is empty.
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
            // Until the first frame is decoded, the shimmer says it's coming.
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) =>
                frame == null
                ? const AppShimmer(
                    child: AppSkeletonBox(height: double.infinity, radius: 0),
                  )
                : child,
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
