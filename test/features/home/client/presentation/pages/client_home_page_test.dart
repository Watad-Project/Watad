import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/display/app_business_mini_card.dart';
import 'package:watad/core/components/display/app_status_badge.dart';
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
  Widget buildTestPage({
    required FakeClientHomeRepository repository,
    VoidCallback? onStartPostProject,
    int currentHour = 10,
  }) {
    final bloc = ClientHomeBloc(
      ClientGetHomeProfileUseCase(repository),
      ClientGetSuggestedContractorsUseCase(repository),
    )..add(const ClientHomeStarted());

    return BlocProvider<ClientHomeBloc>.value(
      value: bloc,
      child: ClientHomePage(
        onStartPostProject: onStartPostProject,
        currentHour: currentHour,
      ),
    );
  }

  testWidgets('renders greeting, search, banner, and contractors on success', (
    tester,
  ) async {
    const profile = ClientHomeProfile(
      id: 'c-1',
      fullName: 'Ahmad Al-Mansour',
      isPhoneVerified: true,
    );
    const contractors = [
      ClientSuggestedContractor(
        id: 'con-1',
        companyName: 'Binaa Construction',
        specializedField: 'Contracting',
        ratingLabel: '4.8',
        projectsLabel: '64 projects',
        isVerified: true,
      ),
    ];
    final repo = FakeClientHomeRepository(
      profileResult: const Success(profile),
      contractorsResult: const Success(contractors),
    );

    await pumpLocalizedApp(tester, buildTestPage(repository: repo));
    await tester.pumpAndSettle();

    expect(find.byType(ClientHomeGreetingHeader), findsOneWidget);
    expect(find.textContaining('Ahmad Al-Mansour'), findsOneWidget);
    expect(find.byType(AppStatusBadge), findsOneWidget);

    expect(find.byType(ClientSearchBar), findsOneWidget);
    expect(find.byType(ClientPostProjectBanner), findsOneWidget);
    expect(find.byType(ClientSuggestedContractorsSection), findsOneWidget);
    expect(find.byType(AppBusinessMiniCard), findsOneWidget);
    expect(find.text('Binaa Construction'), findsOneWidget);
  });

  testWidgets('triggers onStartPostProject when banner button tapped', (
    tester,
  ) async {
    var wasTapped = false;
    final repo = FakeClientHomeRepository();

    await pumpLocalizedApp(
      tester,
      buildTestPage(
        repository: repo,
        onStartPostProject: () {
          wasTapped = true;
        },
      ),
    );
    await tester.pumpAndSettle();

    final startButton = find.descendant(
      of: find.byType(ClientPostProjectBanner),
      matching: find.byType(FilledButton),
    );
    await tester.tap(startButton);
    await tester.pumpAndSettle();

    expect(wasTapped, isTrue);
  });

  testWidgets('shows error state with retry when profile loading fails', (
    tester,
  ) async {
    final repo = FakeClientHomeRepository(
      profileResult: const Failed<ClientHomeProfile>(NetworkFailure()),
    );

    await pumpLocalizedApp(tester, buildTestPage(repository: repo));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    expect(find.byType(OutlinedButton), findsOneWidget);
  });
}
