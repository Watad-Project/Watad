import 'package:watad/core/error/result.dart';
import 'package:watad/features/support/shared/domain/entities/support_new_report.dart';
import 'package:watad/features/support/shared/domain/entities/support_report.dart';

abstract interface class SupportRepository {
  /// My reports, newest first.
  Future<Result<List<SupportReport>>> getMyReports();

  /// Sends [report]; it starts `open`.
  Future<Result<void>> sendReport(SupportNewReport report);
}
