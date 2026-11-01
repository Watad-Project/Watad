part of 'my_item_form_bloc.dart';

enum MyItemFormStatus { initial, loading, ready, submitting, saved, failure }

final class MyItemFormState {
  const MyItemFormState({
    this.status = MyItemFormStatus.initial,
    this.itemId,
    this.name = '',
    this.description = '',
    this.priceText = '',
    this.stockText = '',
    this.category,
    this.photos = const [],
    this.isActive = true,
    this.removedAt,
    this.removalReason,
    this.showValidationErrors = false,
    this.loadFailure,
    this.submitFailure,
    this.savedItem,
  });

  static const int minNameLength = 2;
  static const int maxNameLength = 150;
  static const int maxDescriptionLength = 2000;
  static const int maxPhotos = 6;

  final MyItemFormStatus status;
  final String? itemId;
  final String name;
  final String description;
  final String priceText;
  final String stockText;
  final MarketplaceCategory? category;
  final List<String> photos;
  final bool isActive;
  final DateTime? removedAt;
  final String? removalReason;
  final bool showValidationErrors;
  final Failure? loadFailure;
  final Failure? submitFailure;
  final MarketplaceItem? savedItem;

  bool get isEditing => itemId != null;

  /// True when an admin removed this listing (`removed_at != null`), making
  /// the form read-only.
  bool get isRemoved => removedAt != null;

  /// Parses [priceText] (supporting Western and Arabic-Indic digits) into
  /// [Money] when valid and strictly greater than zero.
  Money? get parsedPrice {
    final normalized = _normalizeDigits(priceText).trim();
    if (normalized.isEmpty) return null;
    final pattern = RegExp(r'^\d+(\.\d{1,2})?$');
    if (!pattern.hasMatch(normalized)) return null;
    final parts = normalized.split('.');
    final whole = int.tryParse(parts[0]);
    if (whole == null) return null;
    final fractionText = parts.length > 1 ? parts[1].padRight(2, '0') : '00';
    final fraction = int.tryParse(fractionText);
    if (fraction == null) return null;
    final money = Money.halalas(whole * 100 + fraction);
    return money > const Money.zero() ? money : null;
  }

  /// Parses [stockText] (supporting Western and Arabic-Indic digits) into a
  /// non-negative integer.
  int? get parsedStock {
    final normalized = _normalizeDigits(stockText).trim();
    if (normalized.isEmpty) return null;
    final count = int.tryParse(normalized);
    if (count == null || count < 0) return null;
    return count;
  }

  String? get nameErrorKey {
    if (!showValidationErrors) return null;
    final trimmed = name.trim();
    if (trimmed.length < minNameLength || trimmed.length > maxNameLength) {
      return 'marketplace.my_items_name_error';
    }
    return null;
  }

  String? get descriptionErrorKey {
    if (!showValidationErrors) return null;
    if (description.trim().length > maxDescriptionLength) {
      return 'marketplace.my_items_description_error';
    }
    return null;
  }

  String? get priceErrorKey {
    if (!showValidationErrors) return null;
    if (parsedPrice == null) return 'marketplace.my_items_price_error';
    return null;
  }

  String? get stockErrorKey {
    if (!showValidationErrors) return null;
    if (parsedStock == null) return 'marketplace.my_items_stock_error';
    return null;
  }

  String? get categoryErrorKey {
    if (!showValidationErrors) return null;
    if (category == null) return 'marketplace.my_items_category_error';
    return null;
  }

  bool get isValid {
    final trimmedName = name.trim();
    return trimmedName.length >= minNameLength &&
        trimmedName.length <= maxNameLength &&
        description.trim().length <= maxDescriptionLength &&
        parsedPrice != null &&
        parsedStock != null &&
        category != null &&
        photos.length <= maxPhotos;
  }

  MyItemFormState copyWith({
    MyItemFormStatus? status,
    String? Function()? itemId,
    String? name,
    String? description,
    String? priceText,
    String? stockText,
    MarketplaceCategory? Function()? category,
    List<String>? photos,
    bool? isActive,
    DateTime? Function()? removedAt,
    String? Function()? removalReason,
    bool? showValidationErrors,
    Failure? Function()? loadFailure,
    Failure? Function()? submitFailure,
    MarketplaceItem? Function()? savedItem,
  }) {
    return MyItemFormState(
      status: status ?? this.status,
      itemId: itemId == null ? this.itemId : itemId(),
      name: name ?? this.name,
      description: description ?? this.description,
      priceText: priceText ?? this.priceText,
      stockText: stockText ?? this.stockText,
      category: category == null ? this.category : category(),
      photos: photos ?? this.photos,
      isActive: isActive ?? this.isActive,
      removedAt: removedAt == null ? this.removedAt : removedAt(),
      removalReason: removalReason == null
          ? this.removalReason
          : removalReason(),
      showValidationErrors: showValidationErrors ?? this.showValidationErrors,
      loadFailure: loadFailure == null ? this.loadFailure : loadFailure(),
      submitFailure: submitFailure == null
          ? this.submitFailure
          : submitFailure(),
      savedItem: savedItem == null ? this.savedItem : savedItem(),
    );
  }

  static String _normalizeDigits(String input) {
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      if (rune >= 0x0660 && rune <= 0x0669) {
        buffer.write(rune - 0x0660);
      } else if (rune == 0x066B || rune == 0x002C) {
        buffer.write('.');
      } else {
        buffer.writeCharCode(rune);
      }
    }
    return buffer.toString();
  }
}
