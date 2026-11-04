import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/report_type.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/support/shared/domain/entities/support_new_report.dart';
import 'package:watad/features/support/shared/domain/entities/support_target.dart';
import 'package:watad/features/support/shared/domain/usecases/send_report_use_case.dart';

import '../../../../../helpers/fake_support_repository.dart';

void main() {
  test('sends the report with its description trimmed', () async {
    final repository = FakeSupportRepository();

    final result = await SendReportUseCase(repository)(
      const SupportNewReport(
        type: ReportType.scam,
        description: '  طلب مني الدفع خارج التطبيق  ',
        target: SupportTarget(kind: SupportTargetKind.user, id: 'u-2'),
      ),
    );

    expect(result, isA<Success<void>>());
    final sent = repository.sent.single;
    expect(sent.description, 'طلب مني الدفع خارج التطبيق');
    expect(sent.target?.kind, SupportTargetKind.user);
    expect(sent.target?.id, 'u-2');
  });

  test('fewer than 5 characters is refused before sending', () async {
    final repository = FakeSupportRepository();

    final result = await SendReportUseCase(repository)(
      const SupportNewReport(type: ReportType.other, description: ' ab  '),
    );

    expect(
      (result as Failed).failure.messageKey,
      'support.error_description_short',
    );
    expect(repository.sent, isEmpty);
  });

  test('more than 5000 characters is refused before sending', () async {
    final repository = FakeSupportRepository();

    final result = await SendReportUseCase(repository)(
      SupportNewReport(type: ReportType.other, description: 'a' * 5001),
    );

    expect(
      (result as Failed).failure.messageKey,
      'support.error_description_long',
    );
    expect(repository.sent, isEmpty);
  });
}
