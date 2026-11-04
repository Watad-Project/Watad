import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/support/shared/domain/usecases/get_my_reports_use_case.dart';
import 'package:watad/features/support/shared/presentation/bloc/support_reports_bloc.dart';

import '../../../../../helpers/fake_support_repository.dart';

void main() {
  test('emits LoadInProgress then LoadSuccess', () async {
    final bloc = SupportReportsBloc(
      GetMyReportsUseCase(FakeSupportRepository()),
    );
    final states = bloc.stream.take(2).toList();

    bloc.add(const SupportReportsFetched());

    final emitted = await states;
    expect(emitted.first, isA<SupportReportsLoadInProgress>());
    expect((emitted.last as SupportReportsLoadSuccess).reports, hasLength(2));
    await bloc.close();
  });

  test('emits LoadInProgress then LoadFailure', () async {
    final repository = FakeSupportRepository()
      ..reportsResult = const Failed(NetworkFailure());
    final bloc = SupportReportsBloc(GetMyReportsUseCase(repository));
    final states = bloc.stream.take(2).toList();

    bloc.add(const SupportReportsFetched());

    final emitted = await states;
    expect(
      (emitted.last as SupportReportsLoadFailure).failure,
      isA<NetworkFailure>(),
    );
    await bloc.close();
  });
}
