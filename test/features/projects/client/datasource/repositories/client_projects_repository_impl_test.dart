import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/task_status.dart';
import 'package:watad/core/enums/task_update_decision.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/projects/client/datasource/models/client_project_model.dart';
import 'package:watad/features/projects/client/datasource/models/client_project_offer_model.dart';
import 'package:watad/features/projects/client/datasource/models/client_project_task_model.dart';
import 'package:watad/features/projects/client/datasource/models/client_saved_address_model.dart';
import 'package:watad/features/projects/client/datasource/models/client_task_update_model.dart';
import 'package:watad/features/projects/client/datasource/remote/client_projects_remote_data_source.dart';
import 'package:watad/features/projects/client/datasource/repositories/client_projects_repository_impl.dart';
import 'package:watad/features/projects/client/domain/entities/client_new_project.dart';
import 'package:watad/features/projects/client/domain/entities/client_project.dart';
import 'package:watad/features/projects/client/domain/entities/client_project_task.dart';
import 'package:watad/features/projects/client/domain/entities/client_replace_deed_params.dart';
import 'package:watad/features/projects/client/domain/entities/client_saved_address.dart';
import 'package:watad/features/projects/client/domain/entities/client_task_status_params.dart';
import 'package:watad/features/projects/client/domain/entities/client_task_update.dart';

class _FakeClientProjectsRemoteDataSource
    implements ClientProjectsRemoteDataSource {
  Object? error;
  List<ClientSavedAddressModel> addresses = [];
  ClientSavedAddressModel createdAddress = const ClientSavedAddressModel(
    id: 'addr_new',
    name: 'Office',
    city: 'Riyadh',
    district: 'Al-Narjis',
    street: 'King Fahd',
    buildingNumber: '1234',
    postalCode: '12345',
    formattedAddress: 'Riyadh · Al-Narjis',
  );

  @override
  Future<void> createProject(ClientNewProject project) async {
    final err = error;
    if (err != null) throw err;
  }

  @override
  Future<List<ClientSavedAddressModel>> getSavedAddresses() async {
    final err = error;
    if (err != null) throw err;
    return addresses;
  }

  @override
  Future<String> uploadProjectPhoto({required String filePath}) async =>
      'projects/user_1/photo.jpg';

  @override
  Future<String> uploadDeedDocument({required String filePath}) async =>
      'user_1/deed.pdf';

  @override
  Future<ClientSavedAddressModel> createAddress({
    required String name,
    required String city,
    required String district,
    required String street,
    required String buildingNumber,
    required String postalCode,
  }) async {
    final err = error;
    if (err != null) throw err;
    return createdAddress;
  }

  List<ClientProjectModel> projects = [];

  /// The new deeds, as (project id, file path).
  final List<(String, String)> replacedDeeds = [];

  @override
  Future<List<ClientProjectModel>> getMyProjects() async {
    final err = error;
    if (err != null) throw err;
    return projects;
  }

  @override
  Future<ClientProjectModel> getProject(String projectId) async {
    final err = error;
    if (err != null) throw err;
    return projects.firstWhere((p) => p.id == projectId);
  }

  @override
  Future<List<ClientProjectOfferModel>> getOffers(String projectId) async {
    final err = error;
    if (err != null) throw err;
    return [];
  }

  @override
  Future<void> acceptOffer(String offerId, Money expectedAmount) async {
    final err = error;
    if (err != null) throw err;
  }

  @override
  Future<void> replaceDeed(String projectId, String filePath) async {
    final err = error;
    if (err != null) throw err;
    replacedDeeds.add((projectId, filePath));
  }

  List<ClientProjectTaskModel> tasks = [];

  @override
  Future<List<ClientProjectTaskModel>> getProjectTasks(String projectId) async {
    final err = error;
    if (err != null) throw err;
    return tasks;
  }

  @override
  Future<ClientProjectTaskModel> getProjectTask(String taskId) async {
    final err = error;
    if (err != null) throw err;
    return tasks.firstWhere((t) => t.id == taskId);
  }

  /// The answers sent to proposed tasks, as (task id, status).
  final List<(String, TaskStatus)> taskStatuses = [];

  @override
  Future<void> setTaskStatus(String taskId, TaskStatus status) async {
    final err = error;
    if (err != null) throw err;
    taskStatuses.add((taskId, status));
  }

  ClientTaskUpdateModel? taskUpdate;

  @override
  Future<ClientTaskUpdateModel> getTaskUpdate(String updateId) async {
    final err = error;
    if (err != null) throw err;
    return taskUpdate ?? (throw StateError('Set taskUpdate first'));
  }

  /// The decisions sent, as (update id, decision, reason, details).
  final List<(String, TaskUpdateDecision, String?, String?)> decisions = [];

  @override
  Future<void> decideTaskUpdate(
    String updateId,
    TaskUpdateDecision decision, {
    String? rejectionReason,
    String? rejectionDetails,
  }) async {
    final err = error;
    if (err != null) throw err;
    decisions.add((updateId, decision, rejectionReason, rejectionDetails));
  }
}

void main() {
  group('ClientProjectsRepositoryImpl', () {
    test('getSavedAddresses returns Success with list of addresses', () async {
      final fakeRemote = _FakeClientProjectsRemoteDataSource();
      fakeRemote.addresses = [
        const ClientSavedAddressModel(
          id: 'addr_1',
          name: 'Home',
          city: 'Riyadh',
          district: 'Al-Narjis',
          street: 'Anas Ibn Malik',
          buildingNumber: '4210',
          postalCode: '13324',
          formattedAddress: 'Riyadh · Al-Narjis',
        ),
      ];

      final repo = ClientProjectsRepositoryImpl(fakeRemote);
      final result = await repo.getSavedAddresses();

      expect(result, isA<Success<List<ClientSavedAddress>>>());
      final data = (result as Success<List<ClientSavedAddress>>).data;
      expect(data.length, 1);
      expect(data.first.id, 'addr_1');
    });

    test('getSavedAddresses returns Failed when remote throws', () async {
      final fakeRemote = _FakeClientProjectsRemoteDataSource();
      fakeRemote.error = Exception('Network error');

      final repo = ClientProjectsRepositoryImpl(fakeRemote);
      final result = await repo.getSavedAddresses();

      expect(result, isA<Failed<List<ClientSavedAddress>>>());
    });

    test('createAddress returns Success with created address', () async {
      final fakeRemote = _FakeClientProjectsRemoteDataSource();
      final repo = ClientProjectsRepositoryImpl(fakeRemote);

      final result = await repo.createAddress(
        name: 'Office',
        city: 'Riyadh',
        district: 'Al-Narjis',
        street: 'King Fahd',
        buildingNumber: '1234',
        postalCode: '12345',
      );

      expect(result, isA<Success<ClientSavedAddress>>());
      final data = (result as Success<ClientSavedAddress>).data;
      expect(data.id, 'addr_new');
      expect(data.name, 'Office');
    });

    test('createAddress returns Failed when remote throws', () async {
      final fakeRemote = _FakeClientProjectsRemoteDataSource();
      fakeRemote.error = Exception('Database error');

      final repo = ClientProjectsRepositoryImpl(fakeRemote);
      final result = await repo.createAddress(
        name: 'Office',
        city: 'Riyadh',
        district: 'Al-Narjis',
        street: 'King Fahd',
        buildingNumber: '1234',
        postalCode: '12345',
      );

      expect(result, isA<Failed<ClientSavedAddress>>());
    });

    test('getMyProjects returns the projects', () async {
      final fakeRemote = _FakeClientProjectsRemoteDataSource()
        ..projects = [
          ClientProjectModel.fromJson({
            'id': 'p-1',
            'title': 'فيلا سكنية',
            'status': 'open',
            'city': 'المدينة المنورة',
            'pending_offer_count': 1,
            'created_at': '2026-10-18T08:00:00+00:00',
          }),
        ];

      final result = await ClientProjectsRepositoryImpl(fakeRemote)
          .getMyProjects();

      expect(result, isA<Success<List<ClientProject>>>());
      expect((result as Success<List<ClientProject>>).data.single.id, 'p-1');
    });

    test('replaceDeed sends the new file for the project', () async {
      final fakeRemote = _FakeClientProjectsRemoteDataSource();

      final result = await ClientProjectsRepositoryImpl(fakeRemote).replaceDeed(
        const ClientReplaceDeedParams(
          projectId: 'p-1',
          filePath: '/tmp/deed.pdf',
        ),
      );

      expect(result, isA<Success<void>>());
      expect(fakeRemote.replacedDeeds, [('p-1', '/tmp/deed.pdf')]);
    });

    test('replaceDeed returns Failed when the upload fails', () async {
      final fakeRemote = _FakeClientProjectsRemoteDataSource()
        ..error = Exception('Storage error');

      final result = await ClientProjectsRepositoryImpl(fakeRemote).replaceDeed(
        const ClientReplaceDeedParams(
          projectId: 'p-1',
          filePath: '/tmp/deed.pdf',
        ),
      );

      expect(result, isA<Failed<void>>());
    });

    test('getProjectTasks returns the tasks', () async {
      final fakeRemote = _FakeClientProjectsRemoteDataSource()
        ..tasks = [
          ClientProjectTaskModel.fromJson(const {
            'id': 't-1',
            'title': 'اللياسة الداخلية',
            'description': 'لياسة الجدران الداخلية',
            'status': 'accepted',
          }),
        ];

      final result = await ClientProjectsRepositoryImpl(fakeRemote)
          .getProjectTasks('p-1');

      expect(result, isA<Success<List<ClientProjectTask>>>());
      expect(
        (result as Success<List<ClientProjectTask>>).data.single.id,
        't-1',
      );
    });

    test('getProjectTasks returns Failed when the read fails', () async {
      final fakeRemote = _FakeClientProjectsRemoteDataSource()
        ..error = Exception('Network error');

      final result = await ClientProjectsRepositoryImpl(fakeRemote)
          .getProjectTasks('p-1');

      expect(result, isA<Failed<List<ClientProjectTask>>>());
    });

    test('setTaskStatus sends the client\'s answer', () async {
      final fakeRemote = _FakeClientProjectsRemoteDataSource();

      final result = await ClientProjectsRepositoryImpl(fakeRemote)
          .setTaskStatus(
            const ClientTaskStatusParams(
              taskId: 't-5',
              status: TaskStatus.accepted,
            ),
          );

      expect(result, isA<Success<void>>());
      expect(fakeRemote.taskStatuses, [('t-5', TaskStatus.accepted)]);
    });

    test('getTaskUpdate returns the update', () async {
      final fakeRemote = _FakeClientProjectsRemoteDataSource()
        ..taskUpdate = ClientTaskUpdateModel.fromJson(const {
          'id': 'u-3',
          'task_title': 'اللياسة الداخلية',
          'proposed_state': 'done',
          'decision': 'pending',
          'created_at': '2026-10-24T06:40:00+00:00',
          'project_status': 'in_progress',
        });

      final result = await ClientProjectsRepositoryImpl(fakeRemote)
          .getTaskUpdate('u-3');

      expect(result, isA<Success<ClientTaskUpdate>>());
      expect((result as Success<ClientTaskUpdate>).data.id, 'u-3');
    });

    test('getTaskUpdate returns Failed when the read fails', () async {
      final fakeRemote = _FakeClientProjectsRemoteDataSource()
        ..error = Exception('Network error');

      final result = await ClientProjectsRepositoryImpl(fakeRemote)
          .getTaskUpdate('u-3');

      expect(result, isA<Failed<ClientTaskUpdate>>());
    });

    test('acceptTaskUpdate accepts it, without a reason', () async {
      final fakeRemote = _FakeClientProjectsRemoteDataSource();

      final result = await ClientProjectsRepositoryImpl(fakeRemote)
          .acceptTaskUpdate('u-3');

      expect(result, isA<Success<void>>());
      expect(fakeRemote.decisions, [
        ('u-3', TaskUpdateDecision.accepted, null, null),
      ]);
    });
  });
}
