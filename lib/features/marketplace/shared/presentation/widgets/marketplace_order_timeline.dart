import 'package:flutter/material.dart';
import 'package:watad/core/components/display/app_timeline.dart';
import 'package:watad/core/enums/order_status.dart';
import 'package:watad/features/marketplace/shared/domain/entities/order_status_change.dart';
import 'package:watad/features/marketplace/shared/presentation/widgets/marketplace_order_labels.dart';

/// The order's timeline: each status it reached, with when, from
/// `v_order_status_history`; then, while it is still on its way, the steps
/// still to come. Only the app's own status labels, never the change's
/// note.
class MarketplaceOrderTimeline extends StatelessWidget {
  const MarketplaceOrderTimeline({
    required this.status,
    required this.history,
    super.key,
  });

  /// The order's status now, from `v_my_orders`.
  final OrderStatus status;
  final List<OrderStatusChange> history;

  /// The way an order goes when nothing stops it.
  static const List<OrderStatus> _path = [
    OrderStatus.pendingPayment,
    OrderStatus.paid,
    OrderStatus.shipped,
    OrderStatus.delivered,
  ];

  @override
  Widget build(BuildContext context) {
    final isFinished =
        status == OrderStatus.delivered ||
        status == OrderStatus.cancelled ||
        status == OrderStatus.refunded;
    final position = _path.indexOf(status);
    final upcoming = isFinished || position < 0
        ? const <OrderStatus>[]
        : _path.sublist(position + 1);
    return AppTimeline(
      key: const Key('order_timeline'),
      items: [
        for (final (index, change) in history.indexed)
          AppTimelineItem(
            title: MarketplaceOrderLabels.status(context, change.newStatus),
            subtitle: MarketplaceOrderLabels.dateTime(
              context,
              change.changedAt,
            ),
            state: index == history.length - 1 && !isFinished
                ? AppTimelineState.current
                : AppTimelineState.done,
          ),
        for (final next in upcoming)
          AppTimelineItem(
            title: MarketplaceOrderLabels.status(context, next),
            state: AppTimelineState.upcoming,
          ),
      ],
    );
  }
}
