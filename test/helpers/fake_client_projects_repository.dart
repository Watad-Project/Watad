import 'package:watad/core/di/injection.dart';
import 'package:watad/core/enums/offer_status.dart';
import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/projects/client/domain/entities/client_accept_offer_params.dart';
import 'package:watad/features/projects/client/domain/entities/client_project.dart';
import 'package:watad/features/projects/client/domain/entities/client_project_offer.dart';
import 'package:watad/features/projects/client/domain/repositories/client_projects_repository.dart';
import 'package:watad/features/projects/client/domain/usecases/client_accept_offer_use_case.dart';
import 'package:watad/features/projects/client/domain/usecases/client_get_my_projects_use_case.dart';
import 'package:watad/features/projects/client/domain/usecases/client_get_project_by_id_use_case.dart';
import 'package:watad/features/projects/client/domain/usecases/client_get_project_offers_use_case.dart';
import 'package:watad/features/projects/client/presentation/bloc/client_project_offers_bloc.dart';
import 'package:watad/features/projects/client/presentation/bloc/client_projects_bloc.dart';

class FakeClientProjectsRepository implements ClientProjectsRepository {
  Result<List<ClientProject>> getMyProjectsResult = Success([
    ClientProject(
      id: 'proj-1',
      title: 'Villa Renovation',
      status: ProjectStatus.open,
      city: 'Riyadh',
      district: 'Al-Malqa',
      budget: const Money.halalas(5000000),
      pendingOfferCount: 2,
      createdAt: DateTime.utc(2026, 10, 15),
    ),
  ]);

  Result<ClientProject> getProjectByIdResult = Success(
    ClientProject(
      id: 'proj-1',
      title: 'Villa Renovation',
      status: ProjectStatus.open,
      city: 'Riyadh',
      district: 'Al-Malqa',
      budget: const Money.halalas(5000000),
      pendingOfferCount: 2,
      createdAt: DateTime.utc(2026, 10, 15),
    ),
  );

  Result<List<ClientProjectOffer>> getProjectOffersResult = Success([
    ClientProjectOffer(
      id: 'offer-1',
      projectId: 'proj-1',
      amount: const Money.halalas(4500000),
      status: OfferStatus.pending,
      createdAt: DateTime.utc(2026, 10, 15),
      contractorName: 'Al-Bina Construction',
      isContractorVerified: true,
      contractorRating: 4.9,
      durationMonths: 6,
      message: 'We can deliver on time with high quality.',
    ),
  ]);

  Result<void> acceptOfferResult = const Success(null);

  final List<ClientAcceptOfferParams> acceptedParams = [];

  @override
  Future<Result<List<ClientProject>>> getMyProjects() async =>
      getMyProjectsResult;

  @override
  Future<Result<ClientProject>> getProjectById(String projectId) async =>
      getProjectByIdResult;

  @override
  Future<Result<List<ClientProjectOffer>>> getProjectOffers(
    String projectId,
  ) async => getProjectOffersResult;

  @override
  Future<Result<void>> acceptOffer(ClientAcceptOfferParams params) async {
    acceptedParams.add(params);
    return acceptOfferResult;
  }
}

void registerFakeClientProjectsBloc(ClientProjectsRepository repository) {
  getIt.registerFactory<ClientProjectsBloc>(
    () => ClientProjectsBloc(ClientGetMyProjectsUseCase(repository)),
  );
}

void registerFakeClientProjectOffersBloc(ClientProjectsRepository repository) {
  getIt.registerFactory<ClientProjectOffersBloc>(
    () => ClientProjectOffersBloc(
      ClientGetProjectByIdUseCase(repository),
      ClientGetProjectOffersUseCase(repository),
      ClientAcceptOfferUseCase(repository),
    ),
  );
}
