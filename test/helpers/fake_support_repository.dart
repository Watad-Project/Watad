import 'package:watad/core/di/injection.dart';
import 'package:watad/core/enums/report_status.dart';
import 'package:watad/core/enums/report_type.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/support/shared/domain/entities/support_new_report.dart';
import 'package:watad/features/support/shared/domain/entities/support_report.dart';
import 'package:watad/features/support/shared/domain/entities/support_target.dart';
import 'package:watad/features/support/shared/domain/repositories/support_repository.dart';
import 'package:watad/features/support/shared/support_injection.dart';

/// A resolved report about an order, and an open one about nothing.
final List<SupportReport> fakeSupportReports = [
  SupportReport(
    id: 'r-2',
    type: ReportType.paymentIssue,
    description: 'دفعت للطلب ولم تتغير حالته',
    status: ReportStatus.resolved,
    resolutionNote: 'تم تحديث حالة الطلب، شكرًا لك',
    targetKind: SupportTargetKind.order,
    createdAt: DateTime.utc(2026, 11, 2, 10),
    resolvedAt: DateTime.utc(2026, 11, 3, 9),
  ),
  SupportReport(
    id: 'r-1',
    type: ReportType.technicalIssue,
    description: 'التطبيق يغلق عند فتح الخريطة',
    status: ReportStatus.open,
    createdAt: DateTime.utc(2026, 10, 30, 8),
  ),
];

/// A hand-written [SupportRepository]: it answers with the results you set
/// and records every report sent (APP_ARCHITECTURE.md §16).
class FakeSupportRepository implements SupportRepository {
  Result<List<SupportReport>> reportsResult = Success(fakeSupportReports);
  Result<void> sendResult = const Success(null);

  final List<SupportNewReport> sent = [];

  @override
  Future<Result<List<SupportReport>>> getMyReports() async => reportsResult;

  @override
  Future<Result<void>> sendReport(SupportNewReport report) async {
    sent.add(report);
    return sendResult;
  }
}

/// For tests that open the support routes: the real registrations, with
/// [repository] in place of Supabase. Reset getIt after the test.
void registerFakeSupport([FakeSupportRepository? repository]) {
  registerSupportDependencies(getIt);
  getIt
    ..unregister<SupportRepository>()
    ..registerSingleton<SupportRepository>(
      repository ?? FakeSupportRepository(),
    );
}
