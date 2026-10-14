import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/auth/shared/domain/entities/sign_up_profile.dart';
import 'package:watad/features/auth/shared/domain/repositories/auth_repository.dart';

class SaveUserProfileUseCase implements UseCase<String, SignUpProfile> {
  const SaveUserProfileUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Result<String>> call(SignUpProfile params) async {
    if (params.fullName.trim().isEmpty) {
      return const Failed(ValidationFailure('validation.name_required'));
    }
    final digits = params.nationalId.trim();
    if (digits.length != 10 || !RegExp(r'^\d{10}$').hasMatch(digits)) {
      return const Failed(ValidationFailure('validation.national_id_invalid'));
    }
    return _repository.saveProfile(params);
  }
}
