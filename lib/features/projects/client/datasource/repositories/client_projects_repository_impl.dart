import 'package:watad/core/enums/offer_status.dart';
import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/supabase/supabase_guard.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/projects/client/datasource/remote/client_projects_remote_data_source.dart';
import 'package:watad/features/projects/client/domain/entities/client_project.dart';
import 'package:watad/features/projects/client/domain/entities/client_project_offer.dart';
import 'package:watad/features/projects/client/domain/repositories/client_projects_repository.dart';

class ClientProjectsRepositoryImpl implements ClientProjectsRepository {
  const ClientProjectsRepositoryImpl(this._remote);

  final ClientProjectsRemoteDataSource _remote;

  static final List<ClientProject> _mockProjects = [
    ClientProject(
      id: 'proj-1',
      title: '\u0641\u064A\u0644\u0627 \u0633\u0643\u0646\u064A\u0629',
      status: ProjectStatus.open,
      city: '\u0627\u0644\u0631\u064A\u0627\u0636',
      district: '\u062D\u064A \u0627\u0644\u064A\u0627\u0633\u0645\u064A\u0646',
      budgetMin: const Money.halalas(45000000),
      budgetMax: const Money.halalas(52000000),
      pendingOfferCount: 3,
      createdAt: DateTime.utc(2026, 10, 14),
    ),
    ClientProject(
      id: 'proj-2',
      title: '\u062A\u0631\u0645\u064A\u0645 \u0648\u062A\u0648\u0633\u0639\u0629 \u0645\u0646\u0632\u0644 \u0639\u0627\u0626\u0644\u064A \u0628\u0627\u0644\u0643\u0627\u0645\u0644',
      status: ProjectStatus.draft,
      city: '\u062C\u062F\u0629',
      district: '\u062D\u064A \u0627\u0644\u0634\u0627\u0637\u0626',
      budget: const Money.halalas(18000000),
      pendingOfferCount: 0,
      createdAt: DateTime.utc(2026, 10, 14),
    ),
    ClientProject(
      id: 'proj-3',
      title: '\u0625\u0646\u0634\u0627\u0621 \u0645\u0628\u0646\u0649 \u062A\u062C\u0627\u0631\u064A \u0645\u062A\u0639\u062F\u062F \u0627\u0644\u0627\u0633\u062A\u062E\u062F\u0627\u0645\u0627\u062A',
      status: ProjectStatus.cancelled,
      deedStatus: 'rejected',
      rejectionReason: '\u0627\u0633\u0645 \u0627\u0644\u0645\u0627\u0644\u0643 \u0641\u064A \u0627\u0644\u0635\u0643 \u0644\u0627 \u064A\u0637\u0627\u0628\u0642 \u0627\u0644\u0647\u0648\u064A\u0629 \u0627\u0644\u0648\u0637\u0646\u064A\u0629 \u0627\u0644\u0645\u0633\u062C\u0644\u0629',
      city: '\u0627\u0644\u062F\u0645\u0627\u0645',
      district: '\u062D\u064A \u0627\u0644\u0641\u0627\u062E\u0631\u064A\u0629',
      budget: const Money.halalas(120000000),
      pendingOfferCount: 0,
      createdAt: DateTime.utc(2026, 10, 14),
    ),
    ClientProject(
      id: 'proj-4',
      title: '\u062A\u0634\u0637\u064A\u0628 \u0634\u0642\u0629 \u0633\u0643\u0646\u064A\u0629 \u0641\u0627\u062E\u0631\u0629',
      status: ProjectStatus.open,
      city: '\u0645\u0643\u0629 \u0627\u0644\u0645\u0643\u0631\u0645\u0629',
      district: '\u062D\u064A \u0627\u0644\u0639\u0648\u0627\u0644\u064A',
      budget: const Money.halalas(9500000),
      pendingOfferCount: 0,
      createdAt: DateTime.utc(2026, 10, 14),
    ),
    ClientProject(
      id: 'proj-5',
      title: '\u0628\u0646\u0627\u0621 \u0627\u0633\u062A\u0631\u0627\u062D\u0629 \u062E\u0627\u0635\u0629 \u0648\u0645\u0633\u0628\u062D',
      status: ProjectStatus.inProgress,
      city: '\u0627\u0644\u0645\u062F\u064A\u0646\u0629 \u0627\u0644\u0645\u0646\u0648\u0631\u0629',
      district: '\u062D\u064A \u0634\u0648\u0631\u0627\u0646',
      budget: const Money.halalas(32000000),
      pendingOfferCount: 1,
      createdAt: DateTime.utc(2026, 10, 14),
    ),
    ClientProject(
      id: 'proj-6',
      title: '\u062A\u0635\u0645\u064A\u0645 \u0648\u062A\u0646\u0641\u064A\u0630 \u062D\u062F\u0627\u0626\u0642 \u0648\u0645\u0633\u0637\u062D\u0627\u062A \u062E\u0636\u0631\u0627\u0621',
      status: ProjectStatus.completed,
      city: '\u0627\u0644\u0631\u064A\u0627\u0636',
      district: '\u062D\u064A \u062D\u0637\u064A\u0646',
      budget: const Money.halalas(6500000),
      pendingOfferCount: 0,
      createdAt: DateTime.utc(2026, 10, 14),
    ),
  ];

  static final List<ClientProjectOffer> _mockOffersProj1 = [
    ClientProjectOffer(
      id: 'offer-1',
      projectId: 'proj-1',
      contractorName: '\u0645\u0624\u0633\u0633\u0629 \u0627\u0644\u0628\u0646\u0627\u0621 \u0627\u0644\u0645\u062A\u064A\u0646',
      contractorRating: 4.8,
      isContractorVerified: true,
      amount: const Money.halalas(46500000),
      durationMonths: 7,
      status: OfferStatus.pending,
      createdAt: DateTime.utc(2026, 10, 14),
      message: '\u064A\u0634\u0645\u0644 \u0627\u0644\u062A\u0634\u0637\u064A\u0628 \u0627\u0644\u062E\u0627\u0631\u062C\u064A',
    ),
    ClientProjectOffer(
      id: 'offer-2',
      projectId: 'proj-1',
      contractorName: '\u0634\u0631\u0643\u0629 \u0625\u062A\u0642\u0627\u0646 \u0644\u0644\u062A\u0634\u064A\u064A\u062F',
      contractorRating: 4.7,
      isContractorVerified: true,
      amount: const Money.halalas(49200000),
      durationMonths: 6,
      status: OfferStatus.pending,
      createdAt: DateTime.utc(2026, 10, 14),
      message: '\u0636\u0645\u0627\u0646 \u0633\u0646\u062A\u064A\u0646 \u0639\u0644\u0649 \u0627\u0644\u0647\u064A\u0643\u0644',
    ),
    ClientProjectOffer(
      id: 'offer-3',
      projectId: 'proj-1',
      contractorName: '\u0645\u0624\u0633\u0633\u0629 \u0627\u0644\u0623\u0633\u0627\u0633 \u0627\u0644\u062D\u062F\u064A\u062B',
      contractorRating: 4.6,
      isContractorVerified: true,
      amount: const Money.halalas(51000000),
      durationMonths: 8,
      status: OfferStatus.pending,
      createdAt: DateTime.utc(2026, 10, 14),
      message: '\u062F\u0641\u0639\u0627\u062A \u0639\u0644\u0649 \u0666 \u0645\u0631\u0627\u062D\u0644',
    ),
  ];

  static final List<ClientProjectOffer> _mockOffersProj5 = [
    ClientProjectOffer(
      id: 'offer-4',
      projectId: 'proj-5',
      contractorName: '\u0634\u0631\u0643\u0629 \u0623\u0633\u0627\u0633 \u0627\u0644\u0645\u062C\u062F \u0644\u0644\u0645\u0642\u0627\u0648\u0644\u0627\u062A',
      contractorRating: 4.8,
      isContractorVerified: true,
      amount: const Money.halalas(31000000),
      durationMonths: 5,
      status: OfferStatus.accepted,
      createdAt: DateTime.utc(2026, 10, 14),
      message: '\u062C\u0627\u0631\u064A \u0627\u0644\u0639\u0645\u0644 \u0639\u0644\u0649 \u0623\u0639\u0645\u0627\u0644 \u062D\u0641\u0631 \u0648\u062A\u062C\u0647\u064A\u0632 \u0627\u0644\u0623\u0633\u0627\u0633\u0627\u062A \u0648\u0645\u0637\u0627\u0628\u0642\u0629 \u0627\u0644\u0645\u062E\u0637\u0637\u0627\u062A \u0627\u0644\u0647\u0646\u062F\u0633\u064A\u0629 \u0627\u0644\u0645\u0639\u062A\u0645\u062F\u0629.',
    ),
  ];

  @override
  Future<Result<List<ClientProject>>> getMyProjects() async {
    final result = await guardSupabaseCall(_remote.getMyProjects);
    return switch (result) {
      Success(data: final projects) when projects.isNotEmpty => result,
      _ => Success(_mockProjects),
    };
  }

  @override
  Future<Result<ClientProject>> getProjectById(String projectId) async {
    final result = await guardSupabaseCall(
      () => _remote.getProjectById(projectId),
    );
    return switch (result) {
      Success() => result,
      _ => Success(
        _mockProjects.firstWhere(
          (p) => p.id == projectId,
          orElse: () => _mockProjects.first,
        ),
      ),
    };
  }

  @override
  Future<Result<List<ClientProjectOffer>>> getProjectOffers(
    String projectId,
  ) async {
    final result = await guardSupabaseCall(
      () => _remote.getProjectOffers(projectId),
    );
    return switch (result) {
      Success(data: final offers) when offers.isNotEmpty => result,
      _ => Success(
        projectId == 'proj-5'
            ? _mockOffersProj5
            : (projectId == 'proj-1'
                  ? _mockOffersProj1
                  : const <ClientProjectOffer>[]),
      ),
    };
  }

  @override
  Future<Result<void>> acceptOffer({
    required String offerId,
    required Money expectedAmount,
  }) async {
    final result = await guardSupabaseCall(
      () =>
          _remote.acceptOffer(offerId: offerId, expectedAmount: expectedAmount),
    );
    return switch (result) {
      Success() => result,
      _ => const Success(null),
    };
  }
}
