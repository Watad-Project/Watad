import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/projects/client/domain/entities/client_deed_verification_status.dart';
import 'package:watad/features/projects/client/domain/entities/client_project.dart';
import 'package:watad/features/projects/client/domain/usecases/client_get_project_use_case.dart';
import 'package:watad/features/projects/client/domain/usecases/client_replace_deed_use_case.dart';
import 'package:watad/features/projects/client/presentation/bloc/client_project_deed_bloc.dart';

import '../../../../../helpers/fake_client_projects_repository.dart';

void main() {
  final rejected = ClientProject(
    id: 'p-1',
    title: 'فيلا سكنية',
    status: ProjectStatus.draft,
    city: 'المدينة المنورة',
    pendingOfferCount: 0,
    deedStatus: ClientDeedVerificationStatus.rejected,
    deedRejectionReason: 'الصك غير واضح',
    createdAt: DateTime.utc(2026, 10, 18),
  );

  late FakeClientProjectsRepository repository;

  ClientProjectDeedBloc buildBloc() => ClientProjectDeedBloc(
    ClientGetProjectUseCase(repository),
    ClientReplaceDeedUseCase(repository),
  );

  Future<ClientProjectDeedBloc> loadedBloc() async {
    final bloc = buildBloc()..add(const ClientProjectDeedFetched('p-1'));
    await bloc.stream.firstWhere(
      (s) => s.status == ClientProjectDeedStatus.ready,
    );
    return bloc;
  }

  setUp(() {
    repository = FakeClientProjectsRepository()
      ..projectResult = Success(rejected);
  });

  test('loads the project and why its deed was rejected', () async {
    final bloc = await loadedBloc();

    expect(bloc.state.project?.deedRejectionReason, 'الصك غير واضح');
    expect(bloc.state.failure, isNull);
    await bloc.close();
  });

  test('fails when the project cannot load', () async {
    repository.projectResult = const Failed(NotFoundFailure());
    final bloc = buildBloc()..add(const ClientProjectDeedFetched('p-1'));

    final state = await bloc.stream.firstWhere(
      (s) => s.status == ClientProjectDeedStatus.failure,
    );
    expect(state.failure, isA<NotFoundFailure>());
    await bloc.close();
  });

  test('sending without a file sends nothing', () async {
    final bloc = await loadedBloc()
      ..add(const ClientProjectDeedSubmitted());
    await pumpEventQueue();

    expect(repository.replacedDeeds, isEmpty);
    expect(bloc.state.isSent, isFalse);
    await bloc.close();
  });

  test('the picked deed is sent back to review', () async {
    final bloc = await loadedBloc()
      ..add(
        const ClientProjectDeedPicked(
          filePath: '/tmp/deed.pdf',
          fileName: 'deed.pdf',
        ),
      )
      ..add(const ClientProjectDeedSubmitted());

    final state = await bloc.stream.firstWhere((s) => s.isSent);
    expect(repository.replacedDeeds, [('p-1', '/tmp/deed.pdf')]);
    expect(state.fileName, 'deed.pdf');
    expect(state.isSending, isFalse);
    await bloc.close();
  });

  test('a failed upload keeps the file and shows why', () async {
    repository.replaceDeedResult = const Failed(NetworkFailure());
    final bloc = await loadedBloc()
      ..add(
        const ClientProjectDeedPicked(
          filePath: '/tmp/deed.pdf',
          fileName: 'deed.pdf',
        ),
      )
      ..add(const ClientProjectDeedSubmitted());

    final state = await bloc.stream.firstWhere((s) => s.errorKey != null);
    expect(state.errorKey, const NetworkFailure().messageKey);
    expect(state.isSent, isFalse);
    expect(state.isSending, isFalse);
    expect(state.filePath, '/tmp/deed.pdf');
    await bloc.close();
  });
}
