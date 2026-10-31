part of 'my_item_form_bloc.dart';

sealed class MyItemFormEvent {
  const MyItemFormEvent();
}

/// Initializes the form: blank when [itemId] is null, or loads the existing
/// listing when editing.
final class MyItemFormStarted extends MyItemFormEvent {
  const MyItemFormStarted({this.itemId});
  final String? itemId;
}

final class MyItemFormNameChanged extends MyItemFormEvent {
  const MyItemFormNameChanged(this.name);
  final String name;
}

final class MyItemFormDescriptionChanged extends MyItemFormEvent {
  const MyItemFormDescriptionChanged(this.description);
  final String description;
}

final class MyItemFormPriceChanged extends MyItemFormEvent {
  const MyItemFormPriceChanged(this.priceText);
  final String priceText;
}

final class MyItemFormStockChanged extends MyItemFormEvent {
  const MyItemFormStockChanged(this.stockText);
  final String stockText;
}

final class MyItemFormCategoryChanged extends MyItemFormEvent {
  const MyItemFormCategoryChanged(this.category);
  final MarketplaceCategory category;
}

final class MyItemFormPhotoAdded extends MyItemFormEvent {
  const MyItemFormPhotoAdded(this.path);
  final String path;
}

final class MyItemFormPhotoRemoved extends MyItemFormEvent {
  const MyItemFormPhotoRemoved(this.index);
  final int index;
}

final class MyItemFormSubmitted extends MyItemFormEvent {
  const MyItemFormSubmitted();
}
