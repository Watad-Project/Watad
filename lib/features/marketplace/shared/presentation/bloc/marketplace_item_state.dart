part of 'marketplace_item_bloc.dart';

/// [unavailable]: hidden, deleted or removed by an admin («المنتج غير متاح»).
enum MarketplaceItemLoadStatus {
  initial,
  loading,
  success,
  unavailable,
  failure,
}

enum MarketplaceItemAddStatus { idle, adding, added, failed }

final class MarketplaceItemState {
  const MarketplaceItemState({
    this.itemId = '',
    this.status = MarketplaceItemLoadStatus.initial,
    this.item,
    this.quantity = 1,
    this.failure,
    this.addStatus = MarketplaceItemAddStatus.idle,
    this.addition,
    this.addFailure,
  });

  final String itemId;
  final MarketplaceItemLoadStatus status;
  final MarketplaceItem? item;

  /// How many «أضف للسلة» adds: 1 to the stock.
  final int quantity;

  /// Why the item couldn't load.
  final Failure? failure;

  final MarketplaceItemAddStatus addStatus;

  /// What the last «أضف للسلة» did.
  final CartAddition? addition;

  /// Why the last «أضف للسلة» failed.
  final Failure? addFailure;

  MarketplaceItemState copyWith({
    String? itemId,
    MarketplaceItemLoadStatus? status,
    MarketplaceItem? Function()? item,
    int? quantity,
    Failure? Function()? failure,
    MarketplaceItemAddStatus? addStatus,
    CartAddition? Function()? addition,
    Failure? Function()? addFailure,
  }) {
    return MarketplaceItemState(
      itemId: itemId ?? this.itemId,
      status: status ?? this.status,
      item: item == null ? this.item : item(),
      quantity: quantity ?? this.quantity,
      failure: failure == null ? this.failure : failure(),
      addStatus: addStatus ?? this.addStatus,
      addition: addition == null ? this.addition : addition(),
      addFailure: addFailure == null ? this.addFailure : addFailure(),
    );
  }
}
