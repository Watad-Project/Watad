import 'package:watad/core/di/injection.dart';
import 'package:watad/core/enums/payment_status.dart';
import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/enums/task_status.dart';
import 'package:watad/core/enums/task_update_decision.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/evidence/shared/domain/entities/evidence_export.dart';
import 'package:watad/features/evidence/shared/domain/entities/evidence_project.dart';
import 'package:watad/features/evidence/shared/domain/entities/project_evidence.dart';
import 'package:watad/features/evidence/shared/domain/repositories/evidence_repository.dart';
import 'package:watad/features/evidence/shared/evidence_injection.dart';

/// A contracted project in progress, as the client sees it.
final EvidenceProject fakeEvidenceProject = EvidenceProject(
  id: 'd22a4b79-80a3-4e44-afc2-25e1fedc7e61',
  title: 'ترميم فيلا في العزيزية',
  status: ProjectStatus.inProgress,
  createdAt: DateTime.utc(2026, 10, 2, 9),
  otherParty: 'مقاولات الخبر',
  agreedAmount: const Money.halalas(45000000),
);

/// A synced project whose chain record matches, except one payment.
final ProjectEvidence fakeProjectEvidence = ProjectEvidence(
  exportId: '6f1c2d3e-4b5a-4c6d-8e7f-0a1b2c3d4e5f',
  exportedAt: DateTime.utc(2026, 11, 1, 8, 30),
  exportedByRole: 'owner',
  project: EvidenceProjectDetails(
    title: 'ترميم فيلا في العزيزية',
    status: ProjectStatus.inProgress,
    city: 'المدينة المنورة',
    district: 'العزيزية',
    description: 'ترميم الواجهة وتجديد السباكة.',
    createdAt: DateTime.utc(2026, 10, 2, 9),
    startedAt: DateTime.utc(2026, 10, 5, 10),
  ),
  clientName: 'أمير',
  contractorCompany: 'مقاولات الخبر',
  contractorCrNumber: '1010123456',
  agreedPrice: const Money.halalas(45000000),
  tasks: [
    EvidenceTask(
      title: 'هدم الواجهة',
      description: 'إزالة التكسيات القديمة',
      status: TaskStatus.approved,
      amount: const Money.halalas(5000000),
      startDate: DateTime.utc(2026, 10, 6),
      finishDate: DateTime.utc(2026, 10, 12),
      lastDecision: TaskUpdateDecision.accepted,
    ),
    const EvidenceTask(title: 'السباكة', description: ''),
  ],
  payments: [
    EvidencePayment(
      stageNumber: 1,
      amount: const Money.halalas(5000000),
      status: PaymentStatus.paid,
      method: 'bank_transfer',
      paidAt: DateTime.utc(2026, 10, 14, 11),
      bankTransferStatus: 'confirmed',
    ),
  ],
  chainFields: const [
    EvidenceFieldCheck(
      field: 'owner',
      database: 'أمير',
      chain: 'أمير',
      matches: true,
    ),
    EvidenceFieldCheck(
      field: 'ownerEmail',
      database: 'amer@gmail.com',
      chain: 'amer@gmail.com',
      matches: true,
    ),
    EvidenceFieldCheck(
      field: 'agreedPrice',
      database: '450000',
      chain: '450000',
      matches: true,
    ),
  ],
  chainMilestones: const [
    EvidenceMilestoneCheck(
      index: 0,
      description: 'إزالة التكسيات القديمة',
      status: 'approved',
      matches: true,
    ),
  ],
  chainPayments: const [
    EvidencePaymentCheck(
      id: '0b9a8c7d-6e5f-4a3b-9c2d-1e0f9a8b7c6d',
      amount: Money.halalas(5000000),
      date: '2026-10-14',
      matches: false,
      isOnChain: true,
      isInDatabase: true,
    ),
  ],
  matches: false,
  lastSyncedAt: DateTime.utc(2026, 10, 14, 11, 2),
  fingerprint:
      '9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08',
  signature:
      'q5c2l3m4n5o6p7q8r9s0t1u2v3w4x5y6z7a8b9c0d1e2f3g4h5i6j7k8l9m0n1o2==',
  keyId: 'evidence-2026-10',
  publicKey: '11qYAYKxCrfVS_7TyWQHOg7hcvPapiMlrwIaaPcHURo',
);

/// A hand-written [EvidenceRepository]: it answers with the results you set
/// and records every export, in order (APP_ARCHITECTURE.md §16).
class FakeEvidenceRepository implements EvidenceRepository {
  Result<List<EvidenceProject>> projectsResult = Success([fakeEvidenceProject]);
  Result<EvidenceExport> exportResult = Success(
    EvidenceExportReady(fakeProjectEvidence),
  );

  /// The project ids exported.
  final List<String> exports = [];

  @override
  Future<Result<List<EvidenceProject>>> getContractedProjects() async =>
      projectsResult;

  @override
  Future<Result<EvidenceExport>> export(String projectId) async {
    exports.add(projectId);
    return exportResult;
  }
}

/// For tests that open the evidence routes: the real registrations, with
/// [repository] in place of Supabase. Reset getIt after the test.
void registerFakeEvidence(FakeEvidenceRepository repository) {
  registerEvidenceDependencies(getIt);
  getIt
    ..unregister<EvidenceRepository>()
    ..registerSingleton<EvidenceRepository>(repository);
}
