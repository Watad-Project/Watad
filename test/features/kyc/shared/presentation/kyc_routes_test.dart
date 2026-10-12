import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/enums/verification_status.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/router/routes/kyc_routes.dart';
import 'package:watad/features/kyc/shared/domain/entities/kyc_document.dart';
import 'package:watad/features/kyc/shared/domain/repositories/kyc_repository.dart';
import 'package:watad/features/kyc/shared/domain/usecases/get_kyc_document_use_case.dart';
import 'package:watad/features/kyc/shared/domain/usecases/watch_kyc_document_use_case.dart';
import 'package:watad/features/kyc/shared/presentation/bloc/kyc_status_bloc.dart';
import 'package:watad/features/kyc/shared/presentation/pages/status_page.dart';
import 'package:watad/features/splash/shared/domain/entities/splash_destination.dart';
import 'package:watad/features/splash/shared/domain/repositories/splash_repository.dart';
import 'package:watad/features/splash/shared/domain/usecases/get_initial_destination_use_case.dart';
import 'package:watad/features/splash/shared/presentation/bloc/splash_bloc.dart';

import '../../../../helpers/pump_router.dart';

class FakeKycRepository implements KycRepository {
  @override
  Future<Result<KycDocument>> getDocument(KycDocumentType documentType) async =>
      const Success(
        KycDocument(
          id: 'doc-1',
          documentType: KycDocumentType.license,
          status: VerificationStatus.pending,
        ),
      );

  @override
  Stream<Result<KycDocument>> watchDocument(KycDocumentType documentType) =>
      const Stream.empty();
}

class FakeSplashRepository implements SplashRepository {
  @override
  Future<Result<SplashDestination>> determineInitialDestination() async =>
      const Success(SplashDestination.login);
}

void main() {
  setUp(() {
    getIt.registerFactory(
      () => SplashBloc(GetInitialDestinationUseCase(FakeSplashRepository())),
    );
    getIt.registerFactory(
      () => KycStatusBloc(
        GetKycDocumentUseCase(FakeKycRepository()),
        WatchKycDocumentUseCase(FakeKycRepository()),
      ),
    );
  });

  tearDown(getIt.reset);

  testWidgets('status route opens StatusPage at its path', (tester) async {
    final router = await pumpAppRouter(tester);

    router.goNamed(KycRoutes.statusName);
    await tester.pumpAndSettle();

    expect(currentPath(router), KycRoutes.statusPath);
    expect(find.byType(StatusPage), findsOneWidget);
  });
}
