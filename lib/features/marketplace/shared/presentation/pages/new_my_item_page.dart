import 'package:flutter/widgets.dart';
import 'package:watad/features/marketplace/shared/presentation/widgets/my_item_form_view.dart';

/// «إضافة منتج» (`/marketplace/my-items/new`): creates a new marketplace
/// listing for the signed-in seller.
class NewMyItemPage extends StatelessWidget {
  const NewMyItemPage({this.onPickPhoto, super.key});

  final Future<String?> Function()? onPickPhoto;

  @override
  Widget build(BuildContext context) {
    return MyItemFormView(
      titleKey: 'marketplace.my_items_new_title',
      submitLabelKey: 'marketplace.my_items_create_submit',
      onPickPhoto: onPickPhoto,
    );
  }
}
