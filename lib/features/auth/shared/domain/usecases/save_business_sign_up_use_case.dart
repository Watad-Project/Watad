import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/auth/shared/domain/entities/business_sign_up.dart';
import 'package:watad/features/auth/shared/domain/repositories/auth_repository.dart';

class SaveBusinessSignUpUseCase implements UseCase<void, BusinessSignUp> {
  const SaveBusinessSignUpUseCase(this._repository);

  final AuthRepository _repository;

  static final RegExp _crRegExp = RegExp(r'^\d{10}$');
  static final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$',
  );

  @override
  Future<Result<void>> call(BusinessSignUp params) async {
    if (params.companyName.trim().isEmpty) {
      return const Failed(
        ValidationFailure('validation.company_name_required'),
      );
    }
    if (!params.crNumber.trim().contains(_crRegExp)) {
      return const Failed(ValidationFailure('validation.cr_number_invalid'));
    }
    if (!_emailRegExp.hasMatch(params.email.trim())) {
      return const Failed(ValidationFailure('validation.email_invalid'));
    }
    if (params.phone.trim().isEmpty) {
      return const Failed(ValidationFailure('validation.phone_required'));
    }
    return _repository.saveBusinessSignUp(params);
  }
}
