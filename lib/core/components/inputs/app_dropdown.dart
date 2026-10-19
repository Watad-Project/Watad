import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_status_badge.dart';
import 'package:watad/core/components/inputs/app_field_label.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/core/theme/app_tone.dart';

/// One choice of an [AppDropdown].
class AppDropdownOption<T> {
  const AppDropdownOption({
    required this.value,
    required this.title,
    this.subtitle,
    this.subtitleTone = AppTone.neutral,
    this.tag,
    this.tagTone = AppTone.attention,
  });

  final T value;
  final String title;

  /// A line under the title in the open list, e.g. "Needs a title deed".
  final String? subtitle;
  final AppTone subtitleTone;

  /// A short badge next to the chosen value in the closed field.
  final String? tag;
  final AppTone tagTone;
}

/// A select field. Tapping it opens the list of [options] under the field;
/// choosing one closes it and reports the value through [onChanged].
///
/// By default the list opens inside the page and pushes what follows down.
/// With [floating] it floats over the page instead, so a sheet or a form
/// keeps its size: under the field, or above it when there is more room
/// there; a tap outside closes it.
///
/// It is disabled when [onChanged] is null.
class AppDropdown<T> extends StatefulWidget {
  const AppDropdown({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.label,
    this.isRequired = false,
    this.hint,
    this.errorText,
    this.floating = false,
  });

  final List<AppDropdownOption<T>> options;
  final T? value;
  final ValueChanged<T>? onChanged;
  final String? label;

  /// Shows "Required" at the end of the label.
  final bool isRequired;

  /// Shown while nothing is chosen.
  final String? hint;
  final String? errorText;

  /// The list floats over the page instead of pushing it down.
  final bool floating;

  @override
  State<AppDropdown<T>> createState() => _AppDropdownState<T>();
}

class _AppDropdownState<T> extends State<AppDropdown<T>> {
  bool _isOpen = false;

  /// The floating list: where it attaches and how it opens.
  final LayerLink _link = LayerLink();
  final OverlayPortalController _portal = OverlayPortalController();
  final GlobalKey _fieldKey = GlobalKey();

  /// The floating list's tallest size; longer lists scroll.
  static const double _floatingMaxHeight = 280;

  void _toggle() {
    if (_isOpen) return _close();
    if (widget.floating) _portal.show();
    setState(() => _isOpen = true);
  }

  void _close() {
    if (widget.floating) _portal.hide();
    setState(() => _isOpen = false);
  }

  AppDropdownOption<T>? get _selected {
    for (final option in widget.options) {
      if (option.value == widget.value) return option;
    }
    return null;
  }

  void _choose(AppDropdownOption<T> option) {
    _close();
    widget.onChanged?.call(option.value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onChanged != null;
    final selected = _selected;
    final borderColor = widget.errorText != null
        ? AppColors.error
        : _isOpen
        ? AppColors.ink
        : AppColors.borderStrong;

    final field = Semantics(
      button: true,
      expanded: _isOpen,
      enabled: enabled,
      child: Material(
        color: AppColors.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(AppRadius.lg)),
          side: BorderSide(color: borderColor),
        ),
        child: InkWell(
          onTap: enabled ? _toggle : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppSizes.controlHeight,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            selected?.title ?? widget.hint ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: selected == null
                                ? AppTextStyles.body.copyWith(
                                    color: AppColors.textSecondary,
                                  )
                                : AppTextStyles.label,
                          ),
                        ),
                        if (selected?.tag != null) ...[
                          const SizedBox(width: AppSpacing.xs),
                          AppStatusBadge(
                            label: selected!.tag!,
                            tone: selected.tagTone,
                          ),
                        ],
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          AppFieldLabel(label: widget.label!, isRequired: widget.isRequired),
          const SizedBox(height: AppSpacing.xs),
        ],
        if (widget.floating)
          OverlayPortal(
            controller: _portal,
            overlayChildBuilder: _floatingMenu,
            child: TapRegion(
              groupId: this,
              child: CompositedTransformTarget(
                link: _link,
                child: KeyedSubtree(key: _fieldKey, child: field),
              ),
            ),
          )
        else
          field,
        if (widget.errorText != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(
              top: AppSpacing.xxs,
              start: AppSpacing.md,
            ),
            child: Text(
              widget.errorText!,
              style: AppTextStyles.caption.copyWith(color: AppColors.error),
            ),
          ),
        if (!widget.floating)
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: AlignmentDirectional.topCenter,
            child: _isOpen
                ? Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: _menu(selected),
                  )
                : const SizedBox(width: 0),
          ),
      ],
    );
  }

  /// The list floating over the page, as wide as the field: under it, or
  /// above it when there is more room there.
  Widget _floatingMenu(BuildContext context) {
    final box = _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return const SizedBox.shrink();
    final media = MediaQuery.of(context);
    final top = box.localToGlobal(Offset.zero).dy;
    final below =
        media.size.height -
        media.viewPadding.bottom -
        media.viewInsets.bottom -
        (top + box.size.height) -
        AppSpacing.md;
    final above = top - media.viewPadding.top - AppSpacing.md;
    final openUp = below < _floatingMaxHeight && above > below;
    final maxHeight = math.max(
      AppSizes.controlHeight,
      math.min(_floatingMaxHeight, openUp ? above : below),
    );
    return Positioned(
      width: box.size.width,
      child: CompositedTransformFollower(
        link: _link,
        showWhenUnlinked: false,
        targetAnchor: openUp ? Alignment.topLeft : Alignment.bottomLeft,
        followerAnchor: openUp ? Alignment.bottomLeft : Alignment.topLeft,
        offset: Offset(0, openUp ? -AppSpacing.xs : AppSpacing.xs),
        child: TapRegion(
          groupId: this,
          onTapOutside: (_) => _close(),
          child: _menu(_selected, maxHeight: maxHeight),
        ),
      ),
    );
  }

  /// The options. With [maxHeight] (floating) a long list scrolls.
  Widget _menu(AppDropdownOption<T>? selected, {double? maxHeight}) {
    final options = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < widget.options.length; i++) ...[
          if (i > 0) const Divider(),
          _OptionTile<T>(
            option: widget.options[i],
            isSelected: identical(widget.options[i], selected),
            onTap: () => _choose(widget.options[i]),
          ),
        ],
      ],
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.lg)),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.lg)),
        child: maxHeight == null
            ? options
            : ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxHeight),
                child: Material(
                  color: AppColors.surface,
                  child: SingleChildScrollView(child: options),
                ),
              ),
      ),
    );
  }
}

class _OptionTile<T> extends StatelessWidget {
  const _OptionTile({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final AppDropdownOption<T> option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: isSelected,
      inMutuallyExclusiveGroup: true,
      child: Material(
        color: isSelected ? AppColors.primaryLight : AppColors.surface,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(option.title, style: AppTextStyles.label),
                      if (option.subtitle != null)
                        Text(
                          option.subtitle!,
                          style: AppTextStyles.caption.copyWith(
                            color: option.subtitleTone.foreground,
                          ),
                        ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 16,
                      color: AppColors.white,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
