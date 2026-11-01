part of 'checkout_bloc.dart';

enum CheckoutStatus { initial, loading, ready, failure }

enum CheckoutSubmitStatus { idle, submitting, placed, failed }

final class CheckoutState {
  const CheckoutState({
    this.sellerId = '',
    this.status = CheckoutStatus.initial,
    this.review,
    this.addressId,
    this.method,
    this.failure,
    this.submitStatus = CheckoutSubmitStatus.idle,
    this.placed,
    this.submitFailure,
  });

  /// The cart methods offered for a marketplace order; bank transfer is
  /// hidden (ARCHITECTURE.md §15).
  static const List<PaymentMethod> methods = [
    PaymentMethod.mada,
    PaymentMethod.creditCard,
    PaymentMethod.applePay,
    PaymentMethod.stcPay,
  ];

  final String sellerId;
  final CheckoutStatus status;
  final CheckoutReview? review;
  final String? addressId;
  final PaymentMethod? method;

  /// Why the review couldn't load.
  final Failure? failure;

  final CheckoutSubmitStatus submitStatus;
  final PlacedOrder? placed;

  /// Why «تأكيد الطلب» failed.
  final Failure? submitFailure;

  /// Nothing stops the order, and an address and a method are picked.
  bool get canSubmit {
    final review = this.review;
    return status == CheckoutStatus.ready &&
        review != null &&
        review.problem == null &&
        addressId != null &&
        method != null &&
        submitStatus != CheckoutSubmitStatus.submitting;
  }

  CheckoutState copyWith({
    String? sellerId,
    CheckoutStatus? status,
    CheckoutReview? Function()? review,
    String? Function()? addressId,
    PaymentMethod? Function()? method,
    Failure? Function()? failure,
    CheckoutSubmitStatus? submitStatus,
    PlacedOrder? Function()? placed,
    Failure? Function()? submitFailure,
  }) {
    return CheckoutState(
      sellerId: sellerId ?? this.sellerId,
      status: status ?? this.status,
      review: review == null ? this.review : review(),
      addressId: addressId == null ? this.addressId : addressId(),
      method: method == null ? this.method : method(),
      failure: failure == null ? this.failure : failure(),
      submitStatus: submitStatus ?? this.submitStatus,
      placed: placed == null ? this.placed : placed(),
      submitFailure: submitFailure == null
          ? this.submitFailure
          : submitFailure(),
    );
  }
}
