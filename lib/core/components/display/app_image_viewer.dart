import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_network_image.dart';
import 'package:watad/core/components/feedback/app_popup.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';

/// An image full screen on ink, to read it closely (a license, a receipt, a
/// site photo): pinch or double-tap to zoom, drag to move around, × to
/// close.
///
/// Open it with [AppImageViewer.show]:
///
/// ```dart
/// AppImageViewer.show(context, url: document.url, title: typeName);
/// ```
class AppImageViewer extends StatefulWidget {
  const AppImageViewer({required this.url, this.title, super.key});

  final String url;

  /// Shown at the top, and what screen readers say for the image.
  final String? title;

  static Future<void> show(
    BuildContext context, {
    required String url,
    String? title,
  }) {
    return AppPopup.dialog<void>(
      context,
      useSafeArea: false,
      barrierColor: AppColors.ink,
      builder: (_) => AppImageViewer(url: url, title: title),
    );
  }

  @override
  State<AppImageViewer> createState() => _AppImageViewerState();
}

class _AppImageViewerState extends State<AppImageViewer> {
  static const double _maxScale = 5;
  static const double _doubleTapScale = 2.5;

  final TransformationController _transform = TransformationController();
  Offset _doubleTapAt = Offset.zero;

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  /// Zooms in around the tapped point, or back out when zoomed in.
  void _onDoubleTap() {
    if (_transform.value.getMaxScaleOnAxis() > 1) {
      _transform.value = Matrix4.identity();
      return;
    }
    const scale = _doubleTapScale;
    _transform.value = Matrix4.diagonal3Values(scale, scale, 1)
      ..setTranslationRaw(
        -_doubleTapAt.dx * (scale - 1),
        -_doubleTapAt.dy * (scale - 1),
        0,
      );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.title;
    return Dialog.fullscreen(
      backgroundColor: AppColors.ink,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onDoubleTapDown: (details) =>
                  _doubleTapAt = details.localPosition,
              onDoubleTap: _onDoubleTap,
              child: InteractiveViewer(
                transformationController: _transform,
                maxScale: _maxScale,
                child: AppNetworkImage(
                  url: widget.url,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.contain,
                  semanticLabel: title,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsetsDirectional.all(AppSpacing.xs),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    color: AppColors.white,
                    tooltip: context.tr('common.close'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  if (title != null)
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
