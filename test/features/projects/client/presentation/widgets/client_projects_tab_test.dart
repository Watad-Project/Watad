import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/projects/client/domain/usecases/client_get_my_projects_use_case.dart';
import 'package:watad/features/projects/client/presentation/bloc/client_projects_bloc.dart';
import 'package:watad/features/projects/client/presentation/pages/client_projects_page.dart';
import 'package:watad/features/projects/client/presentation/widgets/client_projects_tab.dart';

import '../../../../../helpers/fake_client_projects_repository.dart';
import '../../../../../helpers/pump_component.dart';

void main() {
  testWidgets('ClientProjectsTab renders ClientProjectsPage', (tester) async {
    final fakeRepo = FakeClientProjectsRepository(
      projectsResult: const Success([]),
    );
    final bloc = ClientProjectsBloc(ClientGetMyProjectsUseCase(fakeRepo));

    await pumpLocalizedApp(tester, ClientProjectsTab(bloc: bloc));

    await tester.pump();
    expect(find.byType(ClientProjectsPage), findsOneWidget);
  });
}
