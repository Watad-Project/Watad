import 'package:watad/core/error/result.dart';
import 'package:watad/core/supabase/supabase_guard.dart';
import 'package:watad/features/support/shared/datasource/remote/support_remote_data_source.dart';
import 'package:watad/features/support/shared/domain/entities/support_new_report.dart';
import 'package:watad/features/support/shared/domain/entities/support_report.dart';
import 'package:watad/features/support/shared/domain/repositories/support_repository.dart';

class SupportRepositoryImpl implements SupportRepository {
  const SupportRepositoryImpl(this._remote);

  final SupportRemoteDataSource _remote;

  @override
  Future<Result<List<SupportReport>>> getMyReports() =>
      guardSupabaseCall(_remote.getMyReports);

  @override
  Future<Result<void>> sendReport(SupportNewReport report) =>
      guardSupabaseCall(() => _remote.sendReport(report));
}
