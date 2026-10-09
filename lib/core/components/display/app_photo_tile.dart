import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_image_placeholder.dart';
import 'package:watad/core/theme/app_spacing.dart';

/// A square photo thumbnail, e.g. a photo just taken as task evidence. Shows
/// the striped placeholder (with [placeholderLabel], e.g. its number) until
/// there is an [image].
class AppPhotoTile extends StatelessWidget {
  const AppPhotoTile({
    super.key,
    this.image,
    this.placeholderLabel,
    this.onTap,
    this.size = 72,
    this.semanticLabel,
  });

  final ImageProvider? image;
  final String? placeholderLabel;
  final VoidCallback? onTap;
  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final photo = image;
    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.lg)),
        child: SizedBox.square(
          dimension: size,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (photo == null)
                AppImagePlaceholder(label: placeholderLabel)
              else
                Image(image: photo, fit: BoxFit.cover),
              if (onTap != null)
                Material(
                  type: MaterialType.transparency,
                  child: InkWell(onTap: onTap),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
