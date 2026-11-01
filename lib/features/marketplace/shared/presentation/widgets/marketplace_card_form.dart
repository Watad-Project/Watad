import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/inputs/app_text_field.dart';
import 'package:watad/core/enums/payment_method.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/features/marketplace/shared/domain/entities/card_check.dart';
import 'package:watad/features/marketplace/shared/domain/entities/payment_brand.dart';

/// The demo card form: number in groups of four, expiry `MM/YY`, CVV and
/// the name on the card. The brand shows as text under the number.
///
/// The fields live only here: [onSubmit] hands them to the payment bloc,
/// which keeps nothing but the brand and the last 4 digits. They are
/// cleared when the form goes away.
class MarketplaceCardForm extends StatefulWidget {
  const MarketplaceCardForm({
    required this.method,
    required this.payLabel,
    required this.onSubmit,
    this.check,
    super.key,
  });

  /// `mada` or `credit_card`.
  final PaymentMethod method;

  /// «ادفع ٤٥ ر.س».
  final String payLabel;

  /// The errors of the last send, or null.
  final CardCheck? check;

  final void Function({
    required String number,
    required String expiry,
    required String cvv,
    required String name,
  })
  onSubmit;

  @override
  State<MarketplaceCardForm> createState() => _MarketplaceCardFormState();
}

class _MarketplaceCardFormState extends State<MarketplaceCardForm> {
  final TextEditingController _number = TextEditingController();
  final TextEditingController _expiry = TextEditingController();
  final TextEditingController _cvv = TextEditingController();
  final TextEditingController _name = TextEditingController();
  PaymentBrand? _brand;

  @override
  void initState() {
    super.initState();
    _number.addListener(_onNumberChanged);
  }

  @override
  void dispose() {
    _number.removeListener(_onNumberChanged);
    for (final controller in [_number, _expiry, _cvv, _name]) {
      controller
        ..clear()
        ..dispose();
    }
    super.dispose();
  }

  void _onNumberChanged() {
    final digits = _number.text.replaceAll(' ', '');
    final brand = digits.isEmpty
        ? null
        : widget.method == PaymentMethod.mada
        ? PaymentBrand.mada
        : PaymentBrand.creditCardOf(digits);
    if (brand != _brand) setState(() => _brand = brand);
  }

  @override
  Widget build(BuildContext context) {
    final check = widget.check;
    String? error(String? key) => key == null ? null : context.tr(key);
    final brand = _brand;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          key: const Key('payment_card_number'),
          controller: _number,
          label: context.tr('marketplace.payment.card_number'),
          hint: context.tr('marketplace.payment.card_number_hint'),
          helperText: brand == null
              ? null
              : brand == PaymentBrand.mada
              ? context.tr('marketplace.payment_methods.mada')
              : brand.value,
          errorText: error(check?.numberError),
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          isMonospace: true,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(16),
            _GroupsOfFourFormatter(),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppTextField(
                key: const Key('payment_card_expiry'),
                controller: _expiry,
                label: context.tr('marketplace.payment.expiry'),
                hint: context.tr('marketplace.payment.expiry_hint'),
                errorText: error(check?.expiryError),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                isMonospace: true,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                  _ExpiryFormatter(),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppTextField(
                key: const Key('payment_card_cvv'),
                controller: _cvv,
                label: context.tr('marketplace.payment.cvv'),
                hint: context.tr('marketplace.payment.cvv_hint'),
                errorText: error(check?.cvvError),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                obscureText: true,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          key: const Key('payment_card_name'),
          controller: _name,
          label: context.tr('marketplace.payment.card_name'),
          hint: context.tr('marketplace.payment.card_name_hint'),
          errorText: error(check?.nameError),
          keyboardType: TextInputType.name,
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          context.tr('marketplace.payment.test_cards'),
          style: AppTextStyles.caption,
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          key: const Key('payment_card_submit'),
          label: widget.payLabel,
          icon: Icons.lock_outline,
          onPressed: () => widget.onSubmit(
            number: _number.text,
            expiry: _expiry.text,
            cvv: _cvv.text,
            name: _name.text,
          ),
        ),
      ],
    );
  }
}

/// `4111111111111111` → `4111 1111 1111 1111`.
class _GroupsOfFourFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text;
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// `1228` → `12/28`.
class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text;
    final text = digits.length > 2
        ? '${digits.substring(0, 2)}/${digits.substring(2)}'
        : digits;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
