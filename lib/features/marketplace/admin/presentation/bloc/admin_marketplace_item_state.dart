part of 'admin_marketplace_item_bloc.dart';

enum AdminMarketplaceItemLoadStatus { initial, loading, success, failure }

/// A message to show once after the removal, as a translation key.
final class AdminMarketplaceItemMessage {
  const AdminMarketplaceItemMessage(this.key, {required this.isError});

  final String key;
  final bool isError;
}

final class AdminMarketplaceItemState {
  const AdminMarketplaceItemState({
    this.status = AdminMarketplaceItemLoadStatus.initial,
    this.itemId,
    this.item,
    this.failure,
    this.isBusy = false,
    this.message,
  });

  final AdminMarketplaceItemLoadStatus status;

  /// The listing the page shows, from the route.
  final String? itemId;
  final AdminMarketplaceItem? item;

  /// Why the listing couldn't load; [NotFoundFailure] when there is none.
  final Failure? failure;

  /// The removal is being sent.
  final bool isBusy;
  final AdminMarketplaceItemMessage? message;

  AdminMarketplaceItemState copyWith({
    AdminMarketplaceItemLoadStatus? status,
    String? itemId,
    AdminMarketplaceItem? Function()? item,
    Failure? Function()? failure,
    bool? isBusy,
    AdminMarketplaceItemMessage? Function()? message,
  }) {
    return AdminMarketplaceItemState(
      status: status ?? this.status,
      itemId: itemId ?? this.itemId,
      item: item == null ? this.item : item(),
      failure: failure == null ? this.failure : failure(),
      isBusy: isBusy ?? this.isBusy,
      message: message == null ? this.message : message(),
    );
  }
}
