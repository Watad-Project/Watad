import 'package:flutter/material.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_text_styles.dart';

/// The striped box shown where a photo is missing or still loading. It
/// fills its parent.
class AppImagePlaceholder extends StatelessWidget {
  const AppImagePlaceholder({super.key, this.label});

  /// Optional text in the middle, e.g. a photo number.
  final String? label;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _StripesPainter(),
      child: SizedBox.expand(
        child: label == null
            ? null
            : Center(
                child: Text(
                  label!,
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
      ),
    );
  }
}

class _StripesPainter extends CustomPainter {
  const _StripesPainter();

  static const double _stripe = 9;
  static const double _spacing = 22;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas
      ..clipRect(rect)
      ..drawRect(rect, Paint()..color = AppColors.placeholder);
    final stripe = Paint()
      ..color = AppColors.placeholderStripe
      ..strokeWidth = _stripe;
    // Diagonal stripes from bottom-left to top-right, as in the design.
    for (var x = -size.height; x < size.width; x += _spacing) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        stripe,
      );
    }
  }

  @override
  bool shouldRepaint(_StripesPainter oldDelegate) => false;
}
