import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/features/settings/shared/domain/entities/settings_overview.dart';
import 'package:watad/features/settings/shared/domain/repositories/settings_repository.dart';

class GetSettingsOverviewUseCase
    implements UseCase<SettingsOverview, NoParams> {
  const GetSettingsOverviewUseCase(this._repository);

  final SettingsRepository _repository;

  @override
  Future<Result<SettingsOverview>> call(NoParams params) =>
      _repository.getOverview();
}
