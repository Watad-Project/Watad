import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/projects/client/domain/entities/client_accept_offer_params.dart';
import 'package:watad/features/projects/client/domain/entities/client_new_project.dart';
import 'package:watad/features/projects/client/domain/entities/client_project.dart';
import 'package:watad/features/projects/client/domain/entities/client_project_offer.dart';
import 'package:watad/features/projects/client/domain/entities/client_project_task.dart';
import 'package:watad/features/projects/client/domain/entities/client_replace_deed_params.dart';
import 'package:watad/features/projects/client/domain/entities/client_saved_address.dart';
import 'package:watad/features/projects/client/domain/entities/client_task_status_params.dart';
import 'package:watad/features/projects/client/domain/entities/client_task_update.dart';
import 'package:watad/features/projects/client/domain/entities/client_task_update_rejection.dart';
import 'package:watad/features/projects/client/domain/repositories/client_projects_repository.dart';
import 'package:watad/features/projects/client/domain/usecases/client_create_project_use_case.dart';

class _FakeClientProjectsRepository implements ClientProjectsRepository {
  ClientNewProject? savedProject;

  @override
  Future<Result<void>> createProject(ClientNewProject project) async {
    savedProject = project;
    return const Success(null);
  }

  @override
  Future<Result<List<ClientSavedAddress>>> getSavedAddresses() async =>
      const Success([]);

  @override
  Future<Result<ClientSavedAddress>> createAddress({
    required String name,
    required String city,
    required String district,
    required String street,
    required String buildingNumber,
    required String postalCode,
  }) async => const Success(
    ClientSavedAddress(
      id: 'addr_1',
      name: 'Home',
      city: 'Riyadh',
      formattedAddress: 'Riyadh · An-Narjis',
    ),
  );

  // Not used by these tests (GRA-24's «مشاريعي»).
  @override
  Future<Result<List<ClientProject>>> getMyProjects() =>
      throw UnimplementedError();

  @override
  Future<Result<ClientProject>> getProject(String projectId) =>
      throw UnimplementedError();

  @override
  Future<Result<List<ClientProjectOffer>>> getOffers(String projectId) =>
      throw UnimplementedError();

  @override
  Future<Result<void>> acceptOffer(ClientAcceptOfferParams params) =>
      throw UnimplementedError();

  @override
  Future<Result<void>> replaceDeed(ClientReplaceDeedParams params) =>
      throw UnimplementedError();

  @override
  Future<Result<List<ClientProjectTask>>> getProjectTasks(String projectId) =>
      throw UnimplementedError();

  @override
  Future<Result<ClientProjectTask>> getProjectTask(String taskId) =>
      throw UnimplementedError();

  @override
  Future<Result<void>> setTaskStatus(ClientTaskStatusParams params) =>
      throw UnimplementedError();

  @override
  Future<Result<ClientTaskUpdate>> getTaskUpdate(String updateId) =>
      throw UnimplementedError();

  @override
  Future<Result<void>> acceptTaskUpdate(String updateId) =>
      throw UnimplementedError();

  @override
  Future<Result<void>> rejectTaskUpdate(ClientTaskUpdateRejection rejection) =>
      throw UnimplementedError();
}

void main() {
  group('ClientCreateProjectUseCase', () {
    test('returns ValidationFailure when title is empty', () async {
      final repo = _FakeClientProjectsRepository();
      final useCase = ClientCreateProjectUseCase(repo);

      final result = await useCase(
        const ClientNewProject(title: '', city: 'Riyadh', publish: true),
      );

      expect(result, isA<Failed<void>>());
      final failure = (result as Failed<void>).failure;
      expect(failure, isA<ValidationFailure>());
    });

    test('returns ValidationFailure when city is empty', () async {
      final repo = _FakeClientProjectsRepository();
      final useCase = ClientCreateProjectUseCase(repo);

      final result = await useCase(
        const ClientNewProject(title: 'New Villa', city: '   ', publish: true),
      );

      expect(result, isA<Failed<void>>());
      final failure = (result as Failed<void>).failure;
      expect(failure, isA<ValidationFailure>());
    });

    test('calls repository when params are valid', () async {
      final repo = _FakeClientProjectsRepository();
      final useCase = ClientCreateProjectUseCase(repo);

      final result = await useCase(
        const ClientNewProject(
          title: 'New Villa',
          city: 'Riyadh',
          district: 'Al-Narjis',
          publish: true,
        ),
      );

      expect(result, isA<Success<void>>());
      expect(repo.savedProject?.title, 'New Villa');
      expect(repo.savedProject?.city, 'Riyadh');
    });
  });
}
