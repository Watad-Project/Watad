import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/order_status.dart';
import 'package:watad/core/enums/payment_method.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/marketplace/shared/datasource/models/marketplace_order_model.dart';
import 'package:watad/features/marketplace/shared/domain/entities/order_role.dart';

Map<String, dynamic> _row({
  String status = 'paid',
  String method = 'credit_card',
  String myRole = 'buyer',
  String? cardBrand = 'Visa',
  String? cardLast4 = '1111',
  String? paidAt = '2026-11-01T10:05:00+00:00',
  Map<String, dynamic>? deliveryAddress = const {
    'name': 'المنزل',
    'city': 'المدينة المنورة',
    'district': 'العزيزية',
    'street': 'شارع الملك عبدالله',
    'building_number': '2450',
    'postal_code': '42311',
    'formatted_address':
        '2450 شارع الملك عبدالله، العزيزية، المدينة المنورة 42311',
  },
}) => {
  'id': '7c9e6679-7425-40de-944b-e07fc1f90ae7',
  'status': status,
  'payment_method': method,
  'total_amount': 5000.5,
  'card_brand': cardBrand,
  'card_last4': cardLast4,
  'paid_at': paidAt,
  'created_at': '2026-11-01T10:00:00+00:00',
  'my_role': myRole,
  'buyer_id': 'u-buyer',
  'buyer_name': 'خالد المطيري',
  'buyer_avatar_path': null,
  'buyer_avatar_url': null,
  'seller_id': 'u-seller',
  'seller_name': 'سارة العتيبي',
  'seller_avatar_path': 'u-seller/avatar.jpg',
  'seller_avatar_url': 'https://example.supabase.co/storage/v1/object/public/avatars/u-seller/avatar.jpg',
  'line_count': 2,
  'unit_count': 5,
  'can_review': false,
  'delivery_address': deliveryAddress,
};

void main() {
  test('a paid card order with its delivery address', () {
    final order = MarketplaceOrderModel.fromJson(_row());

    expect(order.status, OrderStatus.paid);
    expect(order.paymentMethod, PaymentMethod.creditCard);
    expect(order.total, const Money.halalas(500050));
    expect(order.myRole, OrderRole.buyer);
    expect(order.cardBrand, 'Visa');
    expect(order.cardLast4, '1111');
    expect(order.paidAt?.isUtc, isTrue);
    expect(order.createdAt.isUtc, isTrue);
    expect(order.sellerAvatarUrl, endsWith('u-seller/avatar.jpg'));
    expect(order.buyerAvatarUrl, isNull);
    expect(order.lineCount, 2);
    expect(order.unitCount, 5);
    expect(order.deliveryAddress?.name, 'المنزل');
    expect(order.deliveryAddress?.formattedAddress, contains('العزيزية'));
    expect(order.number, '7C9E6679');
    expect(order.isCardMethod, isTrue);
    expect(order.isPayableByMe, isFalse);
  });

  test('an unpaid Apple Pay order from before migration 82', () {
    final order = MarketplaceOrderModel.fromJson(
      _row(
        status: 'pending_payment',
        method: 'apple_pay',
        cardBrand: null,
        cardLast4: null,
        paidAt: null,
        deliveryAddress: null,
      ),
    );

    expect(order.status, OrderStatus.pendingPayment);
    expect(order.paymentMethod, PaymentMethod.applePay);
    expect(order.cardBrand, isNull);
    expect(order.cardLast4, isNull);
    expect(order.paidAt, isNull);
    expect(order.deliveryAddress, isNull);
    expect(order.isCardMethod, isFalse);
    expect(order.isPayableByMe, isTrue);
  });

  test('the seller side of a paid Apple Pay order', () {
    final order = MarketplaceOrderModel.fromJson(
      _row(
        method: 'apple_pay',
        myRole: 'seller',
        cardBrand: 'Apple Pay',
        cardLast4: '0000',
      ),
    );

    expect(order.myRole, OrderRole.seller);
    expect(order.cardBrand, 'Apple Pay');
    expect(order.isPayableByMe, isFalse);
  });
}
