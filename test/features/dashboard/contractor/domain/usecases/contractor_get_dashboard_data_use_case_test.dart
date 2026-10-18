import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/payment_status.dart';
import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/enums/task_status.dart';
import 'package:watad/core/enums/verification_status.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/dashboard/contractor/domain/entities/contractor_dashboard_data.dart';
import 'package:watad/features/dashboard/contractor/domain/entities/contractor_dashboard_payment.dart';
import 'package:watad/features/dashboard/contractor/domain/entities/contractor_dashboard_profile.dart';
import 'package:watad/features/dashboard/contractor/domain/entities/contractor_dashboard_project.dart';
import 'package:watad/features/dashboard/contractor/domain/entities/contractor_dashboard_raw_data.dart';
import 'package:watad/features/dashboard/contractor/domain/entities/contractor_dashboard_task.dart';
import 'package:watad/features/dashboard/contractor/domain/repositories/contractor_dashboard_repository.dart';
import 'package:watad/features/dashboard/contractor/domain/usecases/contractor_get_dashboard_data_use_case.dart';

class FakeContractorDashboardRepository
    implements ContractorDashboardRepository {
  FakeContractorDashboardRepository(this.result);

  final Result<ContractorDashboardRawData> result;

  @override
  Future<Result<ContractorDashboardRawData>> getDashboardRawData() async =>
      result;
}

void main() {
  test(
    'computes Riyadh time earnings and task progress from raw data correctly',
    () async {
      // Riyadh is UTC+3. Fixed time: 2026-10-15 12:00 UTC
      final fixedNow = DateTime.utc(2026, 10, 15, 12, 0);

      final rawData = ContractorDashboardRawData(
        profile: const ContractorDashboardProfile(
          companyName: 'مؤسسة البناء المتين',
          verificationStatus: VerificationStatus.verified,
        ),
        payments: [
          // 1. Paid in current month (October)
          ContractorDashboardPayment(
            amount: const Money.halalas(50000),
            status: PaymentStatus.paid,
            paidAt: DateTime.utc(2026, 10, 5, 10, 0),
          ),
          // 2. Paid on Sept 30 22:00 UTC -> Oct 1 01:00 Riyadh time (shifts into current month!)
          ContractorDashboardPayment(
            amount: const Money.halalas(25000),
            status: PaymentStatus.paid,
            paidAt: DateTime.utc(2026, 9, 30, 22, 0),
          ),
          // 3. Paid on Sept 30 20:00 UTC -> Sept 30 23:00 Riyadh time (previous month, excluded)
          ContractorDashboardPayment(
            amount: const Money.halalas(100000),
            status: PaymentStatus.paid,
            paidAt: DateTime.utc(2026, 9, 30, 20, 0),
          ),
          // 4. Processing transfer
          const ContractorDashboardPayment(
            amount: Money.halalas(30000),
            status: PaymentStatus.processing,
          ),
          // 5. Another processing transfer
          const ContractorDashboardPayment(
            amount: Money.halalas(15000),
            status: PaymentStatus.processing,
          ),
          // 6. Pending payment (neither paid nor processing)
          const ContractorDashboardPayment(
            amount: Money.halalas(80000),
            status: PaymentStatus.pending,
          ),
        ],
        opportunitiesCount: 4,
        projects: [
          ContractorDashboardProject(
            id: 'proj-1',
            title: 'ترميم مبنى',
            ownerName: 'محمد السالم',
            status: ProjectStatus.inProgress,
            createdAt: DateTime.utc(2026, 10, 1),
          ),
        ],
        tasks: const [
          ContractorDashboardTask(
            id: 't-1',
            projectId: 'proj-1',
            status: TaskStatus.approved,
          ),
          ContractorDashboardTask(
            id: 't-2',
            projectId: 'proj-1',
            status: TaskStatus.done,
          ),
          ContractorDashboardTask(
            id: 't-3',
            projectId: 'proj-1',
            status: TaskStatus.rejected, // Excluded from total!
          ),
          ContractorDashboardTask(
            id: 't-4',
            projectId: 'other-proj',
            status: TaskStatus.approved,
          ),
        ],
        offers: const [],
      );

      final useCase = ContractorGetDashboardDataUseCase(
        FakeContractorDashboardRepository(Success(rawData)),
        now: () => fixedNow,
      );

      final result = await useCase(const NoParams());

      expect(result, isA<Success<ContractorDashboardData>>());
      final data = (result as Success<ContractorDashboardData>).data;

      // Earnings: 50000 + 25000 = 75000 halalas (750 SAR)
      expect(data.earnings.thisMonthEarnings.halalas, 75000);
      // Pending transfers: 30000 + 15000 = 45000 halalas (450 SAR)
      expect(data.earnings.pendingTransfers.halalas, 45000);

      // Tasks: total = 2 (approved + done, rejected excluded), approved = 1
      expect(data.activeProjects.length, 1);
      final project = data.activeProjects.first;
      expect(project.totalTasksCount, 2);
      expect(project.approvedTasksCount, 1);
      expect(project.progress, 0.5);
    },
  );
}
