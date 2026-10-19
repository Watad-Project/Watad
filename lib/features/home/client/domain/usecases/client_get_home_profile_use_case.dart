import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/home/client/domain/entities/client_home_profile.dart';
import 'package:watad/features/home/client/domain/repositories/client_home_repository.dart';

class ClientGetHomeProfileUseCase
    implements UseCase<ClientHomeProfile, NoParams> {
  const ClientGetHomeProfileUseCase(this._repository);

  final ClientHomeRepository _repository;

  @override
  Future<Result<ClientHomeProfile>> call(NoParams params) =>
      _repository.getProfile();
}
