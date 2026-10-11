import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/auth/shared/domain/entities/business_sign_up.dart';
import 'package:watad/features/auth/shared/domain/usecases/check_email_registered_use_case.dart';
import 'package:watad/features/auth/shared/domain/usecases/save_business_sign_up_use_case.dart';

part 'business_sign_up_event.dart';
part 'business_sign_up_state.dart';

class BusinessSignUpBloc
    extends Bloc<BusinessSignUpEvent, BusinessSignUpState> {
  BusinessSignUpBloc(this._checkEmailRegistered, this._saveBusinessSignUp)
    : super(const BusinessSignUpState()) {
    on<BusinessSignUpCompanyNameChanged>(_onCompanyNameChanged);
    on<BusinessSignUpCrNumberChanged>(_onCrNumberChanged);
    on<BusinessSignUpEmailChanged>(_onEmailChanged);
    on<BusinessSignUpPhoneChanged>(_onPhoneChanged);
    on<BusinessSignUpTermsToggled>(_onTermsToggled);
    on<BusinessSignUpSubmitted>(_onSubmitted);
  }

  final CheckEmailRegisteredUseCase _checkEmailRegistered;
  final SaveBusinessSignUpUseCase _saveBusinessSignUp;

  static final RegExp _crRegExp = RegExp(r'^\d{10}$');
  static final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$',
  );
  static final RegExp _phoneRegExp = RegExp(r'^5\d{8}$');

  void _onCompanyNameChanged(
    BusinessSignUpCompanyNameChanged event,
    Emitter<BusinessSignUpState> emit,
  ) {
    emit(
      state.copyWith(
        companyName: event.companyName,
        companyNameError: () => null,
        generalError: () => null,
      ),
    );
  }

  void _onCrNumberChanged(
    BusinessSignUpCrNumberChanged event,
    Emitter<BusinessSignUpState> emit,
  ) {
    emit(
      state.copyWith(
        crNumber: event.crNumber,
        crNumberError: () => null,
        generalError: () => null,
      ),
    );
  }

  void _onEmailChanged(
    BusinessSignUpEmailChanged event,
    Emitter<BusinessSignUpState> emit,
  ) {
    emit(
      state.copyWith(
        email: event.email,
        emailError: () => null,
        generalError: () => null,
      ),
    );
  }

  void _onPhoneChanged(
    BusinessSignUpPhoneChanged event,
    Emitter<BusinessSignUpState> emit,
  ) {
    emit(
      state.copyWith(
        phone: event.phone,
        phoneError: () => null,
        generalError: () => null,
      ),
    );
  }

  void _onTermsToggled(
    BusinessSignUpTermsToggled event,
    Emitter<BusinessSignUpState> emit,
  ) {
    emit(
      state.copyWith(
        termsAgreed: event.agreed,
        termsError: () => null,
        generalError: () => null,
      ),
    );
  }

  Future<void> _onSubmitted(
    BusinessSignUpSubmitted event,
    Emitter<BusinessSignUpState> emit,
  ) async {
    final companyName = state.companyName.trim();
    final crNumber = state.crNumber.trim();
    final email = state.email.trim();
    final rawPhone = state.phone
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll('+966', '');
    final termsAgreed = state.termsAgreed;

    String? companyNameError;
    if (companyName.isEmpty) {
      companyNameError = 'validation.company_name_required';
    }

    String? crNumberError;
    if (crNumber.isEmpty) {
      crNumberError = 'validation.cr_number_required';
    } else if (!_crRegExp.hasMatch(crNumber)) {
      crNumberError = 'validation.cr_number_invalid';
    }

    String? emailError;
    if (email.isEmpty) {
      emailError = 'validation.email_required';
    } else if (!_emailRegExp.hasMatch(email)) {
      emailError = 'validation.email_invalid';
    }

    String? phoneError;
    if (rawPhone.isEmpty) {
      phoneError = 'validation.phone_required';
    } else if (!_phoneRegExp.hasMatch(rawPhone)) {
      phoneError = 'validation.phone_invalid';
    }

    String? termsError;
    if (!termsAgreed) {
      termsError = 'validation.terms_required';
    }

    if (companyNameError != null ||
        crNumberError != null ||
        emailError != null ||
        phoneError != null ||
        termsError != null) {
      emit(
        state.copyWith(
          companyNameError: () => companyNameError,
          crNumberError: () => crNumberError,
          emailError: () => emailError,
          phoneError: () => phoneError,
          termsError: () => termsError,
        ),
      );
      return;
    }

    emit(state.copyWith(status: BusinessSignUpStatus.inProgress));

    // Check if email is already registered
    final emailCheck = await _checkEmailRegistered(email);
    switch (emailCheck) {
      case Success(:final data):
        if (data) {
          emit(
            state.copyWith(
              status: BusinessSignUpStatus.failure,
              emailError: () => 'validation.email_already_registered',
            ),
          );
          return;
        }
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: BusinessSignUpStatus.failure,
            generalError: () => failure.messageKey,
          ),
        );
        return;
    }

    final data = BusinessSignUp(
      companyName: companyName,
      crNumber: crNumber,
      email: email,
      phone: '+966$rawPhone',
      role: 'contractor',
    );

    final saveResult = await _saveBusinessSignUp(data);
    switch (saveResult) {
      case Success():
        emit(state.copyWith(status: BusinessSignUpStatus.success));
      case Failed(:final failure):
        emit(
          state.copyWith(
            status: BusinessSignUpStatus.failure,
            generalError: () => failure.messageKey,
          ),
        );
    }
  }
}
