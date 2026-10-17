import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/home/client/domain/entities/client_home_profile.dart';
import 'package:watad/features/home/client/domain/entities/client_suggested_contractor.dart';
import 'package:watad/features/home/client/domain/usecases/client_get_home_profile_use_case.dart';
import 'package:watad/features/home/client/domain/usecases/client_get_suggested_contractors_use_case.dart';
import 'package:watad/features/home/client/presentation/bloc/client_home_bloc.dart';
import 'package:watad/features/home/client/presentation/pages/client_home_page.dart';
import 'package:watad/features/home/client/presentation/widgets/client_home_greeting_header.dart';
import 'package:watad/features/home/client/presentation/widgets/client_post_project_banner.dart';
import 'package:watad/features/home/client/presentation/widgets/client_search_bar.dart';
import 'package:watad/features/home/client/presentation/widgets/client_suggested_contractors_section.dart';

import '../../../../../helpers/fake_client_home_repository.dart';
import '../../../../../helpers/pump_component.dart';

void main() {
  group('ClientHomePage', () {
    late FakeClientHomeRepository repository;
    late ClientHomeBloc bloc;

    setUp(() {
      repository = FakeClientHomeRepository();
      bloc = ClientHomeBloc(
        ClientGetHomeProfileUseCase(repository),
        ClientGetSuggestedContractorsUseCase(repository),
      );
    });

    tearDown(() {
      bloc.close();
    });

    Future<void> pumpPage(WidgetTester tester) {
      return pumpLocalizedApp(
        tester,
        BlocProvider<ClientHomeBloc>.value(
          value: bloc,
          child: const ClientHomePage(),
        ),
      );
    }

    testWidgets('shows loading indicator while fetching', (tester) async {
      await pumpPage(tester);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets(
      'shows greeting, search bar, banner and contractors on success',
      (tester) async {
        const profile = ClientHomeProfile(
          fullName: 'Omar Al-Ghamdi',
          isPhoneVerified: true,
        );
        const contractor = ClientSuggestedContractor(
          id: 'c1',
          companyName: 'Elite Contracting',
          rating: 4.8,
          completedProjectsCount: 15,
          isVerified: true,
        );

        repository.profileResult = const Success(profile);
        repository.contractorsResult = const Success([contractor]);

        await tester.runAsync(() async {
          bloc.add(const ClientHomeStarted());
          await bloc.stream.firstWhere(
            (s) => s.status == ClientHomeStatus.success,
          );
        });

        await pumpPage(tester);
        await tester.pump();

        expect(find.byType(ClientHomeGreetingHeader), findsOneWidget);
        expect(find.byType(ClientSearchBar), findsOneWidget);
        expect(find.byType(ClientPostProjectBanner), findsOneWidget);
        expect(find.byType(ClientSuggestedContractorsSection), findsOneWidget);
        expect(find.text('Omar Al-Ghamdi'), findsOneWidget);
        expect(find.text('Elite Contracting'), findsOneWidget);
      },
    );

    testWidgets('shows empty state when contractor list is empty', (
      tester,
    ) async {
      repository.profileResult = const Success(
        ClientHomeProfile(fullName: 'Client', isPhoneVerified: false),
      );
      repository.contractorsResult = const Success([]);

      await tester.runAsync(() async {
        bloc.add(const ClientHomeStarted());
        await bloc.stream.firstWhere(
          (s) => s.status == ClientHomeStatus.success,
        );
      });

      await pumpPage(tester);
      await tester.pump();

      expect(find.byType(ClientSuggestedContractorsSection), findsOneWidget);
      expect(find.text('Elite Contracting'), findsNothing);
    });

    testWidgets('shows error view and retry button on failure', (tester) async {
      repository.profileResult = const Failed(ServerFailure());

      await tester.runAsync(() async {
        bloc.add(const ClientHomeStarted());
        await bloc.stream.firstWhere(
          (s) => s.status == ClientHomeStatus.failure,
        );
      });

      await pumpPage(tester);
      await tester.pump();

      expect(find.byType(ElevatedButton), findsOneWidget);
    });
  });
}
