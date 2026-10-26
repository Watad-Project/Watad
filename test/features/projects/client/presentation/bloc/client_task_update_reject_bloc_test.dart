import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/projects/client/domain/usecases/client_reject_task_update_use_case.dart';
import 'package:watad/features/projects/client/presentation/bloc/client_task_update_reject_bloc.dart';

import '../../../../../helpers/fake_client_projects_repository.dart';

void main() {
  late FakeClientProjectsRepository repository;

  ClientTaskUpdateRejectBloc buildBloc() =>
      ClientTaskUpdateRejectBloc(ClientRejectTaskUpdateUseCase(repository));

  setUp(() => repository = FakeClientProjectsRepository());

  test('sends the reason as read and the details', () async {
    final bloc = buildBloc()
      ..add(
        const ClientTaskUpdateRejectSubmitted(
          updateId: 'u-3',
          reason: 'الأدلة غير كافية',
          details: 'لا تظهر زوايا السقف.',
        ),
      );

    final state = await bloc.stream.firstWhere((s) => s.isSent);
    expect(repository.rejections, [
      ('u-3', 'الأدلة غير كافية', 'لا تظهر زوايا السقف.'),
    ]);
    expect(state.isSending, isFalse);
    await bloc.close();
  });

  test('a refused rejection says why, and can be sent again', () async {
    repository.rejectTaskUpdateResult = const Failed(ConflictFailure());
    final bloc = buildBloc();
    const submitted = ClientTaskUpdateRejectSubmitted(
      updateId: 'u-3',
      reason: 'العمل غير مكتمل',
      details: 'لم تكتمل الواجهة الشرقية.',
    );

    bloc.add(submitted);
    final state = await bloc.stream.firstWhere((s) => s.errorKey != null);
    expect(state.errorKey, 'errors.conflict');
    expect(state.isSent, isFalse);
    expect(state.isSending, isFalse);

    repository.rejectTaskUpdateResult = const Success(null);
    bloc.add(submitted);
    await bloc.stream.firstWhere((s) => s.isSent);
    expect(repository.rejections, hasLength(2));
    await bloc.close();
  });

  test('details that are too long never reach the server', () async {
    final bloc = buildBloc()
      ..add(
        ClientTaskUpdateRejectSubmitted(
          updateId: 'u-3',
          reason: 'أخرى',
          details: 'ت' * 1001,
        ),
      );

    final state = await bloc.stream.firstWhere((s) => s.errorKey != null);
    expect(state.errorKey, 'projects.client.reject_details_too_long');
    expect(repository.rejections, isEmpty);
    await bloc.close();
  });
}
