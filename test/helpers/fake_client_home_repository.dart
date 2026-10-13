import 'package:flutter/widgets.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/router/routes/client_home_routes.dart';
import 'package:watad/features/home/client/domain/entities/client_home_profile.dart';
import 'package:watad/features/home/client/domain/entities/client_suggested_contractor.dart';
import 'package:watad/features/home/client/domain/repositories/client_home_repository.dart';
import 'package:watad/features/home/client/domain/usecases/client_get_home_profile_use_case.dart';
import 'package:watad/features/home/client/domain/usecases/client_get_suggested_contractors_use_case.dart';
import 'package:watad/features/home/client/presentation/bloc/client_home_bloc.dart';
import 'package:watad/features/home/client/presentation/widgets/client_home_tab.dart';

class FakeClientHomeRepository implements ClientHomeRepository {
  FakeClientHomeRepository({
    this.profileResult = const Success(
      ClientHomeProfile(
        id: 'client-1',
        fullName: 'Ahmad Al-Mansour',
        isPhoneVerified: true,
      ),
    ),
    this.contractorsResult = const Success([
      ClientSuggestedContractor(
        id: 'contractor-1',
        companyName: 'Binaa Construction',
        specializedField: 'General Contracting',
        ratingLabel: '4.9',
        projectsLabel: '12 projects',
        isVerified: true,
      ),
    ]),
  });

  Result<ClientHomeProfile> profileResult;
  Result<List<ClientSuggestedContractor>> contractorsResult;

  @override
  Future<Result<ClientHomeProfile>> getProfile() async => profileResult;

  @override
  Future<Result<List<ClientSuggestedContractor>>>
  getSuggestedContractors() async => contractorsResult;
}

void registerFakeClientHomeBloc([FakeClientHomeRepository? repository]) {
  final repo = repository ?? FakeClientHomeRepository();
  getIt
    ..registerFactory(
      () => ClientHomeBloc(
        ClientGetHomeProfileUseCase(repo),
        ClientGetSuggestedContractorsUseCase(repo),
      ),
    )
    ..registerFactory<Widget>(
      () => ClientHomeTab(
        bloc: getIt<ClientHomeBloc>()..add(const ClientHomeStarted()),
      ),
      instanceName: ClientHomeRoutes.homeName,
    );
}
