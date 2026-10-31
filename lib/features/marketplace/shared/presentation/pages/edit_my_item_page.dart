import 'package:flutter/widgets.dart';
import 'package:watad/features/marketplace/shared/presentation/widgets/my_item_form_view.dart';

/// «تعديل المنتج» (`/marketplace/my-items/:itemId/edit`): edits an existing
/// listing or displays it read-only with the admin's removal reason when
/// `removed_at != null`.
class EditMyItemPage extends StatelessWidget {
  const EditMyItemPage({this.onPickPhoto, super.key});

  final Future<String?> Function()? onPickPhoto;

  @override
  Widget build(BuildContext context) {
    return MyItemFormView(
      titleKey: 'marketplace.my_items_edit_title',
      submitLabelKey: 'marketplace.my_items_save_submit',
      onPickPhoto: onPickPhoto,
    );
  }
}
