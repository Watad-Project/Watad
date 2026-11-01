import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_image_placeholder.dart';
import 'package:watad/core/components/display/app_network_image.dart';
import 'package:watad/core/components/layout/app_page_dots.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/core/theme/app_spacing.dart';

/// The item's photos, one page each, with a dot per photo under them; the
/// striped placeholder when the item has none.
class MarketplaceItemGallery extends StatefulWidget {
  const MarketplaceItemGallery({required this.photoUrls, super.key});

  final List<String> photoUrls;

  @override
  State<MarketplaceItemGallery> createState() => _MarketplaceItemGalleryState();
}

class _MarketplaceItemGalleryState extends State<MarketplaceItemGallery> {
  /// About 4:3 on a phone, and never taller on a tablet.
  static const double _height = 260;

  final PageController _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final urls = widget.photoUrls;
    const radius = BorderRadius.all(Radius.circular(AppRadius.lg));
    if (urls.isEmpty) {
      return const SizedBox(
        height: _height,
        child: ClipRRect(borderRadius: radius, child: AppImagePlaceholder()),
      );
    }
    return Column(
      children: [
        SizedBox(
          height: _height,
          child: ClipRRect(
            borderRadius: radius,
            child: PageView.builder(
              key: const Key('marketplace_item_gallery'),
              controller: _controller,
              itemCount: urls.length,
              onPageChanged: (page) => setState(() => _page = page),
              itemBuilder: (context, index) => AppNetworkImage(
                url: urls[index],
                semanticLabel: context.tr(
                  'marketplace.item_details.photo_label',
                  args: [
                    context.formatNumber(index + 1),
                    context.formatNumber(urls.length),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (urls.length > 1) ...[
          const SizedBox(height: AppSpacing.xs),
          AppPageDots(count: urls.length, currentIndex: _page),
        ],
      ],
    );
  }
}
