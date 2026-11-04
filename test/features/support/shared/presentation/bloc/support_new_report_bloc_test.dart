import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/report_type.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/support/shared/domain/entities/support_new_report.dart';
import 'package:watad/features/support/shared/domain/usecases/send_report_use_case.dart';
import 'package:watad/features/support/shared/presentation/bloc/support_new_report_bloc.dart';

import '../../../../../helpers/fake_support_repository.dart';

const _report = SupportNewReport(
  type: ReportType.spam,
  description: 'يرسل لي رسائل إعلانية',
);

void main() {
  test('sending, then sent', () async {
    final repository = FakeSupportRepository();
    final bloc = SupportNewReportBloc(SendReportUseCase(repository));
    final states = bloc.stream.take(2).toList();

    bloc.add(const SupportNewReportSubmitted(_report));

    final emitted = await states;
    expect(emitted.map((s) => s.status), [
      SupportNewReportStatus.sending,
      SupportNewReportStatus.sent,
    ]);
    expect(repository.sent, hasLength(1));
    await bloc.close();
  });

  test('a refused report says why', () async {
    final repository = FakeSupportRepository()
      ..sendResult = const Failed(PermissionFailure());
    final bloc = SupportNewReportBloc(SendReportUseCase(repository));
    final states = bloc.stream.take(2).toList();

    bloc.add(const SupportNewReportSubmitted(_report));

    final emitted = await states;
    expect(emitted.last.status, SupportNewReportStatus.failure);
    expect(emitted.last.failure, isA<PermissionFailure>());
    await bloc.close();
  });
}
