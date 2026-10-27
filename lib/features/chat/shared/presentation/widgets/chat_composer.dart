import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/buttons/app_icon_button.dart';
import 'package:watad/core/components/feedback/app_popup.dart';
import 'package:watad/core/components/feedback/app_snack_bar.dart';
import 'package:watad/core/components/inputs/app_text_field.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/features/chat/shared/domain/entities/chat_photo.dart';

/// The bottom of the conversation: a photo button, the text and send. A
/// picked photo shows above the text, which becomes its caption.
class ChatComposer extends StatefulWidget {
  const ChatComposer({required this.onSend, super.key});

  /// Text, a photo, or both; the composer clears itself after.
  final void Function(String? text, ChatPhoto? photo) onSend;

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  final TextEditingController _text = TextEditingController();
  ChatPhoto? _photo;

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  bool get _canSend => _photo != null || _text.text.trim().isNotEmpty;

  void _send() {
    if (!_canSend) return;
    final text = _text.text.trim();
    widget.onSend(text.isEmpty ? null : text, _photo);
    _text.clear();
    setState(() => _photo = null);
  }

  Future<void> _pickPhoto() async {
    final source = await AppPopup.sheet<ImageSource>(
      context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppButton(
                label: context.tr('chat.camera'),
                icon: Icons.photo_camera_outlined,
                variant: AppButtonVariant.secondary,
                onPressed: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: context.tr('chat.gallery'),
                icon: Icons.photo_library_outlined,
                variant: AppButtonVariant.secondary,
                onPressed: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null || !mounted) return;
    // The same settings as the other photo screens: the picker saves it
    // again, smaller; an iPhone's HEIC photo becomes a JPEG.
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1920,
      maxHeight: 1920,
    );
    if (picked == null || !mounted) return;
    final photo = ChatPhoto(
      bytes: await picked.readAsBytes(),
      name: picked.name,
    );
    if (!mounted) return;
    if (photo.mimeType == null) {
      context.showErrorSnackBar(context.tr('chat.photo_type'));
      return;
    }
    setState(() => _photo = photo);
  }

  @override
  Widget build(BuildContext context) {
    final photo = _photo;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (photo != null) ...[
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.all(
                        Radius.circular(AppRadius.md),
                      ),
                      child: Image.memory(
                        Uint8List.fromList(photo.bytes),
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                        semanticLabel: context.tr('chat.photo'),
                      ),
                    ),
                    PositionedDirectional(
                      top: 0,
                      end: 0,
                      child: AppIconButton(
                        icon: Icons.close_rounded,
                        tooltip: context.tr('chat.remove_photo'),
                        onPressed: () => setState(() => _photo = null),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AppIconButton(
                    icon: Icons.add_photo_alternate_outlined,
                    tooltip: context.tr('chat.add_photo'),
                    onPressed: _pickPhoto,
                  ),
                  Expanded(
                    child: AppTextField(
                      controller: _text,
                      hint: context.tr(
                        photo == null ? 'chat.hint' : 'chat.caption_hint',
                      ),
                      minLines: 1,
                      maxLines: 5,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  AppIconButton(
                    icon: Icons.send_rounded,
                    variant: AppIconButtonVariant.filled,
                    tooltip: context.tr('chat.send'),
                    onPressed: _canSend ? _send : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
