import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:watad/core/enums/order_status.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/core/theme/app_tone.dart';
import 'package:watad/features/marketplace/shared/domain/entities/marketplace_order.dart';

/// The words and tones of an order, the same on the list and the details.
/// Only the app's own labels: never a note or any text from the server.
abstract final class MarketplaceOrderLabels {
  /// «بانتظار الدفع», «مدفوع», …
  static String status(BuildContext context, OrderStatus status) =>
      context.tr('marketplace.order_status.${status.value}');

  /// Waiting on the buyer is orange; delivered green; cancelled and
  /// refunded red; paid and shipped, on their way, gray.
  static AppTone tone(OrderStatus status) => switch (status) {
    OrderStatus.pendingPayment => AppTone.attention,
    OrderStatus.paid || OrderStatus.shipped => AppTone.neutral,
    OrderStatus.delivered => AppTone.success,
    OrderStatus.cancelled || OrderStatus.refunded => AppTone.danger,
  };

  /// «طلب رقم 7C9E6679».
  static String number(BuildContext context, MarketplaceOrder order) =>
      context.tr('marketplace.my_orders.number', args: [order.number]);

  /// «٣ قطع».
  static String units(BuildContext context, MarketplaceOrder order) =>
      context.plural(
        'marketplace.my_orders.units',
        order.unitCount,
        args: [context.formatNumber(order.unitCount)],
      );

  /// «١ نوفمبر ٢٠٢٦».
  static String day(BuildContext context, DateTime time) =>
      DateFormat.yMMMd(_locale(context)).format(time.toLocal());

  /// «١ نوفمبر ٢٠٢٦ ٩:٠٥ ص», on the phone's clock.
  static String dateTime(BuildContext context, DateTime time) =>
      DateFormat.yMMMd(_locale(context)).add_jm().format(time.toLocal());

  /// «طريقة الدفع»: mada, credit card, Apple Pay, …
  static String method(BuildContext context, MarketplaceOrder order) =>
      context.tr('marketplace.payment_methods.${order.paymentMethod.value}');

  /// How it was paid: «Visa •••• 1111» for a card, the wallet's name for
  /// Apple Pay and STC Pay, «لم يُدفع بعد» before that.
  static String payment(BuildContext context, MarketplaceOrder order) {
    if (order.paidAt == null) {
      return context.tr('marketplace.order_details.not_paid_yet');
    }
    final brand = order.cardBrand ?? method(context, order);
    final last4 = order.cardLast4;
    return order.isCardMethod && last4 != null ? '$brand •••• $last4' : brand;
  }

  static String _locale(BuildContext context) => context.isArabic
      ? AppLocalization.arabic.languageCode
      : AppLocalization.english.languageCode;
}
