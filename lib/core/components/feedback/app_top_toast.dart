import 'dart:async';

import 'package:flutter/material.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_motion.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';

/// A message that slides down from the top, above every page and sheet: an
/// in-app notification. A tap opens it ([onTap]); it goes away by itself
/// after [duration], on a swipe up or to the side, or after the tap. One at
/// a time: a new one replaces the one showing.
///
/// ```dart
/// AppTopToast.show(context, title: 'عرض جديد', message: 'وصلك عرض', onTap: …);
/// ```
class AppTopToast extends StatefulWidget {
  const AppTopToast({
    required this.title,
    required this.onDismissed,
    this.message,
    this.icon = Icons.notifications_rounded,
    this.onTap,
    this.duration = defaultDuration,
    super.key,
  });

  final String title;
  final String? message;
  final IconData icon;

  /// What a tap opens; the toast closes either way.
  final VoidCallback? onTap;
  final Duration duration;

  /// Called once it has slid away: the overlay entry is removed.
  final VoidCallback onDismissed;

  static const Duration defaultDuration = Duration(seconds: 4);

  static OverlayEntry? _showing;

  /// Shows a toast above everything in [context]'s app (the root overlay).
  static void show(
    BuildContext context, {
    required String title,
    String? message,
    IconData icon = Icons.notifications_rounded,
    VoidCallback? onTap,
    Duration duration = defaultDuration,
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    _remove(_showing);
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => AppTopToast(
        title: title,
        message: message,
        icon: icon,
        onTap: onTap,
        duration: duration,
        onDismissed: () => _remove(entry),
      ),
    );
    _showing = entry;
    overlay.insert(entry);
  }

  static void _remove(OverlayEntry? entry) {
    if (entry == null) return;
    if (entry.mounted) entry.remove();
    if (identical(_showing, entry)) _showing = null;
  }

  @override
  State<AppTopToast> createState() => _AppTopToastState();
}

class _AppTopToastState extends State<AppTopToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.enter,
    reverseDuration: AppMotion.exit,
  );
  late final Animation<Offset> _slide =
      Tween(begin: const Offset(0, -1.2), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _controller,
          curve: AppMotion.enterCurve,
          reverseCurve: AppMotion.exitCurve,
        ),
      );
  Timer? _timer;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    unawaited(_controller.forward());
    _timer = Timer(widget.duration, _close);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// Slides it back up, then removes it.
  Future<void> _close() async {
    if (_closing) return;
    _closing = true;
    _timer?.cancel();
    await _controller.reverse();
    widget.onDismissed();
  }

  void _tap() {
    widget.onTap?.call();
    unawaited(_close());
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    return PositionedDirectional(
      top: 0,
      start: 0,
      end: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
          child: SlideTransition(
            position: _slide,
            child: Dismissible(
              key: const ValueKey('app-top-toast'),
              // Sideways; a swipe up closes it too (below).
              direction: DismissDirection.horizontal,
              onDismissed: (_) {
                _timer?.cancel();
                widget.onDismissed();
              },
              child: GestureDetector(
                onVerticalDragEnd: (details) {
                  if ((details.primaryVelocity ?? 0) < 0) unawaited(_close());
                },
                child: Semantics(
                  liveRegion: true,
                  button: widget.onTap != null,
                  child: Material(
                    color: AppColors.surface,
                    elevation: 6,
                    shadowColor: AppColors.ink.withValues(alpha: 0.25),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(AppRadius.lg),
                      ),
                      side: BorderSide(color: AppColors.border),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: _tap,
                      child: Padding(
                        padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DecoratedBox(
                              decoration: const BoxDecoration(
                                color: AppColors.primarySoft,
                                shape: BoxShape.circle,
                              ),
                              child: Padding(
                                padding: const EdgeInsetsDirectional.all(
                                  AppSpacing.xs,
                                ),
                                child: Icon(
                                  widget.icon,
                                  size: 20,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.label,
                                  ),
                                  if (message != null && message.isNotEmpty)
                                    Text(
                                      message,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.caption,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
