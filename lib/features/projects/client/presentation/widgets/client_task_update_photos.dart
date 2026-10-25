import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_image_viewer.dart';
import 'package:watad/core/components/display/app_photo_tile.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/core/theme/app_spacing.dart';

/// The evidence photos of an update, as thumbnails that wrap onto new
/// lines; a tap opens one full screen to look at it closely.
class ClientTaskUpdatePhotos extends StatelessWidget {
  const ClientTaskUpdatePhotos({required this.urls, super.key});

  /// Signed links to the photos.
  final List<String> urls;

  static const double _size = 96;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (var i = 0; i < urls.length; i++)
          AppPhotoTile(
            key: ValueKey('client_task_update_photo_$i'),
            image: NetworkImage(urls[i]),
            size: _size,
            semanticLabel: _label(context, i),
            onTap: () => AppImageViewer.show(
              context,
              url: urls[i],
              title: _label(context, i),
            ),
          ),
      ],
    );
  }

  /// «صورة ١».
  static String _label(BuildContext context, int index) => context.tr(
    'projects.client.update_photo',
    args: [context.formatNumber(index + 1)],
  );
}
