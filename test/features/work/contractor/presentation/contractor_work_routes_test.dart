import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/router/routes/contractor_work_routes.dart';
import 'package:watad/features/work/contractor/presentation/pages/contractor_bid_page.dart';
import 'package:watad/features/work/contractor/presentation/pages/contractor_work_page.dart';

import '../../../../helpers/fake_contractor_work_repository.dart';
import '../../../../helpers/fake_splash_repository.dart';
import '../../../../helpers/pump_router.dart';

void main() {
  setUp(() {
    registerFakeSplashBloc(FakeSplashRepository());
    registerFakeContractorWorkTab();
  });

  tearDown(getIt.reset);

  testWidgets('every contractor work route opens its page at its path', (
    tester,
  ) async {
    final router = await pumpAppRouter(tester);

    router.goNamed(ContractorWorkRoutes.workName);
    await tester.pumpAndSettle();

    expect(currentPath(router), ContractorWorkRoutes.workPath);
    expect(find.byType(ContractorWorkPage), findsOneWidget);

    router.goNamed(
      ContractorWorkRoutes.bidName,
      pathParameters: {'projectId': 'proj-1'},
    );
    await tester.pumpAndSettle();

    expect(currentPath(router), '/contractor/work/proj-1/bid');
    expect(find.byType(ContractorBidPage), findsOneWidget);
  });
}
