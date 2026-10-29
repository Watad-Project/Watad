import 'package:flutter/material.dart';
import 'package:watad/core/components/feedback/app_shimmer.dart';
import 'package:watad/core/theme/app_colors.dart';

/// A person's or a business's photo in a circle. Without a photo, or when it
/// can't load, the default avatar shows instead: a person on a soft orange
/// circle. People and businesses never get the striped
/// `AppImagePlaceholder`; that one is for photos of things.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    this.url,
    this.image,
    this.size = 48,
    this.semanticLabel,
    super.key,
  });

  /// The photo's URL, e.g. a public URL from the `avatars` bucket.
  final String? url;

  /// A photo that isn't uploaded yet, e.g. one just picked to replace the
  /// saved one. Shown instead of [url].
  final ImageProvider? image;

  /// The circle's diameter.
  final double size;

  /// What screen readers say, e.g. the name. Without it the avatar is
  /// decoration.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final Widget fallback = _DefaultAvatar(size: size);
    return Semantics(
      label: semanticLabel,
      image: semanticLabel != null,
      excludeSemantics: true,
      child: ClipOval(
        child: SizedBox.square(
          dimension: size,
          child: switch ((image, url)) {
            (final picked?, _) => Image(
              image: picked,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => fallback,
            ),
            (_, final source?) when source.isNotEmpty => Image.network(
              source,
              fit: BoxFit.cover,
              frameBuilder: (context, child, frame, _) => frame == null
                  ? const AppShimmer(
                      child: AppSkeletonBox(height: double.infinity, radius: 0),
                    )
                  : child,
              errorBuilder: (_, _, _) => fallback,
            ),
            _ => fallback,
          },
        ),
      ),
    );
  }
}

/// The default avatar: a person on a soft orange circle.
class _DefaultAvatar extends StatelessWidget {
  const _DefaultAvatar({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.primarySoft,
      child: Center(
        child: Icon(
          Icons.person_rounded,
          size: size * 0.6,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
