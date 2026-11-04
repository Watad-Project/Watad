import 'package:watad/core/enums/payment_method.dart';
import 'package:watad/features/marketplace/shared/domain/entities/cart_line.dart';

/// «تأكيد الطلب»: one seller's lines as the buyer saw them, the delivery
/// address and the payment method.
class CheckoutRequest {
  const CheckoutRequest({
    required this.sellerId,
    required this.lines,
    required this.method,
    required this.addressId,
  });

  final String sellerId;

  /// Each line's quantity and the price shown on the checkout page
  /// ([CartLine.priceWhenAdded]); the order takes the price from the listing
  /// on the server.
  final List<CartLine> lines;

  final PaymentMethod method;
  final String addressId;
}
