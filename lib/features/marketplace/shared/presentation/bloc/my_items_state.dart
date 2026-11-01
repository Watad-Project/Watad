part of 'my_items_bloc.dart';

enum MyItemsStatus { initial, loading, success, failure }

final class MyItemsState {
  const MyItemsState({
    this.status = MyItemsStatus.initial,
    this.items = const [],
    this.filter = MyItemsFilter.all,
    this.busyItemId,
    this.failure,
    this.actionFailure,
    this.actionDoneKey,
  });

  final MyItemsStatus status;
  final List<MarketplaceItem> items;
  final MyItemsFilter filter;

  /// Listing currently being hidden, shown, or deleted.
  final String? busyItemId;

  /// Why the listings couldn't load.
  final Failure? failure;

  /// Why hiding, showing, or deleting a listing failed.
  final Failure? actionFailure;

  /// Translation key of the last completed action (for a snackbar).
  final String? actionDoneKey;

  /// Listings matching the selected [filter] chip.
  List<MarketplaceItem> get visibleItems => [
    for (final item in items)
      if (filter.matches(item)) item,
  ];

  /// Count of listings matching [chip].
  int countOf(MyItemsFilter chip) => [
    for (final item in items)
      if (chip.matches(item)) item,
  ].length;

  MyItemsState copyWith({
    MyItemsStatus? status,
    List<MarketplaceItem>? items,
    MyItemsFilter? filter,
    String? Function()? busyItemId,
    Failure? Function()? failure,
    Failure? Function()? actionFailure,
    String? Function()? actionDoneKey,
  }) {
    return MyItemsState(
      status: status ?? this.status,
      items: items ?? this.items,
      filter: filter ?? this.filter,
      busyItemId: busyItemId == null ? this.busyItemId : busyItemId(),
      failure: failure == null ? this.failure : failure(),
      actionFailure: actionFailure == null
          ? this.actionFailure
          : actionFailure(),
      actionDoneKey: actionDoneKey == null
          ? this.actionDoneKey
          : actionDoneKey(),
    );
  }
}
