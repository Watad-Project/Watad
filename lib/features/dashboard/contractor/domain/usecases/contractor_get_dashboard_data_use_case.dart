import 'package:watad/core/enums/payment_status.dart';
import 'package:watad/core/enums/task_status.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/dashboard/contractor/domain/entities/contractor_dashboard_data.dart';
import 'package:watad/features/dashboard/contractor/domain/entities/contractor_dashboard_earnings.dart';
import 'package:watad/features/dashboard/contractor/domain/entities/contractor_dashboard_raw_data.dart';
import 'package:watad/features/dashboard/contractor/domain/repositories/contractor_dashboard_repository.dart';

/// Fetches and computes the aggregated dashboard data for the signed-in contractor.
class ContractorGetDashboardDataUseCase
    implements UseCase<ContractorDashboardData, NoParams> {
  const ContractorGetDashboardDataUseCase(
    this._repository, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final ContractorDashboardRepository _repository;
  final DateTime Function() _now;

  @override
  Future<Result<ContractorDashboardData>> call(NoParams params) async {
    final result = await _repository.getDashboardRawData();
    return switch (result) {
      Success(:final data) => Success(_calculateDashboardData(data)),
      Failed(:final failure) => Failed(failure),
    };
  }

  ContractorDashboardData _calculateDashboardData(
    ContractorDashboardRawData raw,
  ) {
    // Current month in Riyadh time (UTC+3)
    final riyadhNow = _now().toUtc().add(const Duration(hours: 3));

    var thisMonthEarnings = const Money.zero();
    var pendingTransfers = const Money.zero();

    for (final payment in raw.payments) {
      final paidAt = payment.paidAt;
      if (payment.status == PaymentStatus.paid && paidAt != null) {
        final paidAtRiyadh = paidAt.toUtc().add(const Duration(hours: 3));
        if (paidAtRiyadh.year == riyadhNow.year &&
            paidAtRiyadh.month == riyadhNow.month) {
          thisMonthEarnings = thisMonthEarnings + payment.amount;
        }
      } else if (payment.status == PaymentStatus.processing) {
        pendingTransfers = pendingTransfers + payment.amount;
      }
    }

    final activeProjects = raw.projects.map((project) {
      var approvedCount = 0;
      var totalCount = 0;

      for (final task in raw.tasks) {
        if (task.projectId == project.id &&
            task.status != TaskStatus.rejected) {
          totalCount++;
          if (task.status == TaskStatus.approved) {
            approvedCount++;
          }
        }
      }

      return project.copyWith(
        approvedTasksCount: approvedCount,
        totalTasksCount: totalCount,
      );
    }).toList();

    return ContractorDashboardData(
      profile: raw.profile,
      earnings: ContractorDashboardEarnings(
        thisMonthEarnings: thisMonthEarnings,
        pendingTransfers: pendingTransfers,
      ),
      opportunitiesCount: raw.opportunitiesCount,
      activeProjects: activeProjects,
      myOffers: raw.offers,
    );
  }
}
