import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/projects/client/domain/entities/client_project.dart';
import 'package:watad/features/projects/client/domain/usecases/client_get_my_projects_use_case.dart';
import 'package:watad/features/projects/client/presentation/bloc/client_projects_bloc.dart';
import 'package:watad/features/projects/client/presentation/pages/client_projects_page.dart';
import 'package:watad/features/projects/client/presentation/widgets/client_project_card.dart';

import '../../../../../helpers/fake_client_projects_repository.dart';
import '../../../../../helpers/pump_component.dart';

void main() {
  testWidgets('shows empty view when there are no projects', (tester) async {
    final fakeRepo = FakeClientProjectsRepository(
      projectsResult: const Success<List<ClientProject>>([]),
    );
    final bloc = ClientProjectsBloc(ClientGetMyProjectsUseCase(fakeRepo))
      ..add(const ClientProjectsFetched());

    await pumpLocalizedApp(
      tester,
      BlocProvider<ClientProjectsBloc>.value(
        value: bloc,
        child: const ClientProjectsPage(),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('لا توجد مشاريع حتى الآن'), findsOneWidget);
    expect(find.text('إنشاء مشروع جديد'), findsOneWidget);
  });

  testWidgets('shows project cards when projects exist', (tester) async {
    final sampleProject = ClientProject(
      id: 'proj-1',
      title: 'Residential Villa',
      status: ProjectStatus.open,
      city: 'Riyadh',
      district: 'Al-Yasmin',
      pendingOfferCount: 3,
      createdAt: DateTime.utc(2026, 10, 14),
    );

    final fakeRepo = FakeClientProjectsRepository(
      projectsResult: Success<List<ClientProject>>([sampleProject]),
    );
    final bloc = ClientProjectsBloc(ClientGetMyProjectsUseCase(fakeRepo))
      ..add(const ClientProjectsFetched());

    await pumpLocalizedApp(
      tester,
      BlocProvider<ClientProjectsBloc>.value(
        value: bloc,
        child: const ClientProjectsPage(),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byType(ClientProjectCard), findsOneWidget);
    expect(find.text('Residential Villa'), findsOneWidget);
    expect(find.text('موثّق'), findsOneWidget);
  });

  testWidgets('shows error view on failure with retry action', (tester) async {
    final fakeRepo = FakeClientProjectsRepository(
      projectsResult: const Failed<List<ClientProject>>(NetworkFailure()),
    );
    final bloc = ClientProjectsBloc(ClientGetMyProjectsUseCase(fakeRepo))
      ..add(const ClientProjectsFetched());

    await pumpLocalizedApp(
      tester,
      BlocProvider<ClientProjectsBloc>.value(
        value: bloc,
        child: const ClientProjectsPage(),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('إعادة المحاولة'), findsOneWidget);
  });
}
