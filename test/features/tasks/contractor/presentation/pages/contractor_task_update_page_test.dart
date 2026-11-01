import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/enums/project_status.dart';
import 'package:watad/core/enums/task_status.dart';
import 'package:watad/core/enums/task_update_decision.dart';
import 'package:watad/core/enums/task_update_state.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/supabase/app_session.dart';
import 'package:watad/core/utils/app_notification_links.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_project_task.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_task_evidence_photo.dart';
import 'package:watad/features/tasks/contractor/domain/entities/contractor_task_project.dart';
import 'package:watad/features/tasks/contractor/domain/usecases/contractor_get_project_tasks_use_case.dart';
import 'package:watad/features/tasks/contractor/domain/usecases/contractor_get_task_project_use_case.dart';
import 'package:watad/features/tasks/contractor/domain/usecases/contractor_submit_task_update_use_case.dart';
import 'package:watad/features/tasks/contractor/presentation/bloc/contractor_project_tasks_bloc.dart';
import 'package:watad/features/tasks/contractor/presentation/bloc/contractor_task_update_bloc.dart';
import 'package:watad/features/tasks/contractor/presentation/bloc/contractor_task_update_step_cubit.dart';
import 'package:watad/features/tasks/contractor/presentation/pages/contractor_task_update_page.dart';

import '../../../../../helpers/fake_app_session.dart';
import '../../../../../helpers/fake_contractor_tasks_repository.dart';
import '../../../../../helpers/fake_splash_repository.dart';
import '../../../../../helpers/pump_component.dart';
import '../../../../../helpers/pump_router.dart';

void main() {
  final validPngBytes = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  );

  final sampleProject = ContractorTaskProject(
    id: 'p-1',
    title: 'فيلا سكنية',
    status: ProjectStatus.inProgress,
    ownerName: 'عبدالله الحربي',
    district: 'حي الياسمين',
    agreedAmount: const Money.halalas(48000000),
    totalPaid: const Money.halalas(9000000),
    totalScheduled: const Money.halalas(21000000),
    createdAt: DateTime.utc(2026, 1, 5),
  );

  final openTasks = <ContractorProjectTask>[
    ContractorProjectTask(
      id: 't-1',
      projectId: 'p-1',
      title: 'بناء الجدران والهيكل',
      status: TaskStatus.accepted,
      amount: const Money.halalas(2400000),
      lastUpdateId: 'upd-prev-1',
      lastUpdateDecision: TaskUpdateDecision.accepted,
      lastUpdateAt: DateTime.utc(2026, 2, 10, 12),
      createdAt: DateTime.utc(2026, 1, 19),
    ),
    ContractorProjectTask(
      id: 't-2',
      projectId: 'p-1',
      title: 'تمديد الكهرباء والسباكة',
      status: TaskStatus.accepted,
      createdAt: DateTime.utc(2026, 1, 27),
    ),
  ];

  late FakeContractorTasksRepository repository;

  ContractorTaskUpdateBloc buildUpdateBloc() => ContractorTaskUpdateBloc(
    ContractorGetTaskProjectUseCase(repository),
    ContractorGetProjectTasksUseCase(repository),
    ContractorSubmitTaskUpdateUseCase(repository),
  );

  ContractorProjectTasksBloc buildScheduleBloc() => ContractorProjectTasksBloc(
    ContractorGetTaskProjectUseCase(repository),
    ContractorGetProjectTasksUseCase(repository),
  );

  setUp(() async {
    await getIt.reset();
    AppNotificationLinks.clear();
    registerFakeSplashBloc(FakeSplashRepository());
    repository = FakeContractorTasksRepository()
      ..projectResult = Success(sampleProject)
      ..tasksResult = Success(openTasks);
    getIt
      ..registerFactory<ContractorProjectTasksBloc>(buildScheduleBloc)
      ..registerFactory<ContractorTaskUpdateBloc>(buildUpdateBloc)
      ..registerFactory<ContractorTaskUpdateStepCubit>(
        () => ContractorTaskUpdateStepCubit(initialTaskId: null),
      );
  });

  tearDown(() async {
    await getIt.reset();
    AppNotificationLinks.clear();
  });

  testWidgets(
    'Step 1 (GRA-41) & Step 2 (GRA-42): chooses task, switches state, attaches photo, and submits update',
    (tester) async {
      final bloc = buildUpdateBloc()
        ..add(const ContractorTaskUpdateFetched('p-1'));
      final cubit = ContractorTaskUpdateStepCubit();
      addTearDown(bloc.close);
      addTearDown(cubit.close);

      await pumpLocalizedApp(
        tester,
        MultiBlocProvider(
          providers: [
            BlocProvider.value(value: bloc),
            BlocProvider.value(value: cubit),
          ],
          child: ContractorTaskUpdatePage(
            projectId: 'p-1',
            now: DateTime.utc(2026, 2, 12, 12),
            onPickPhoto: (_) async => ContractorTaskEvidencePhoto(
              bytes: Uint8List.fromList(validPngBytes),
              fileName: 'wall.png',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Step 1 assertions: heading, both open tasks, relative time.
      expect(find.text('ما المهمة التي تريد تحديثها؟'), findsOneWidget);
      expect(find.text('بناء الجدران والهيكل'), findsOneWidget);
      expect(find.text('تمديد الكهرباء والسباكة'), findsOneWidget);
      expect(find.text('آخر تحديث: قبل يومين'), findsOneWidget);
      expect(find.text('لم يُرسل تحديث بعد'), findsOneWidget);

      // Select the second task, then switch back to the first task.
      await tester.tap(find.byKey(const Key('contractor_task_choice_t-2')));
      await tester.pump();
      expect(cubit.state.selectedTaskId, 't-2');

      await tester.tap(find.byKey(const Key('contractor_task_choice_t-1')));
      await tester.pump();
      expect(cubit.state.selectedTaskId, 't-1');

      // Proceed to Step 2.
      await tester.tap(find.byKey(const Key('contractor_task_update_next')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('contractor_task_update_selected_card')),
        findsOneWidget,
      );
      expect(
        find.text('«منجزة» تحتاج قبول العميل لتُنشأ الدفعة.'),
        findsOneWidget,
      );

      // Tapping «اختيار المهمة» returns to Step 1 and preserves selection.
      await tester.tap(
        find.byKey(const Key('contractor_task_update_back_to_step1')),
      );
      await tester.pumpAndSettle();
      expect(find.text('ما المهمة التي تريد تحديثها؟'), findsOneWidget);
      expect(cubit.state.selectedTaskId, 't-1');

      // Advance back to Step 2.
      await tester.tap(find.byKey(const Key('contractor_task_update_next')));
      await tester.pumpAndSettle();

      // Select «منجزة» and try submitting without photos → validation snackbar.
      await tester.tap(
        find.byKey(const Key('contractor_task_update_state_done')),
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('contractor_task_update_submit')));
      await tester.pumpAndSettle();
      expect(
        find.text('أضف صورة واحدة على الأقل لإعلان إنجاز المهمة'),
        findsOneWidget,
      );
      expect(repository.submittedUpdates, isEmpty);

      // Dismiss snackbar and scroll camera tile & note field into view.
      ScaffoldMessenger.of(
        tester.element(find.byType(ContractorTaskUpdatePage)),
      ).hideCurrentSnackBar();
      await tester.pumpAndSettle();

      final cameraFinder = find.byKey(
        const Key('contractor_task_update_camera_tile'),
      );
      await tester.ensureVisible(cameraFinder);
      await tester.pumpAndSettle();
      await tester.tap(cameraFinder);
      await tester.pumpAndSettle();
      expect(cubit.state.photos, hasLength(1));

      final noteFinder = find.byKey(
        const Key('contractor_task_update_note_field'),
      );
      await tester.ensureVisible(noteFinder);
      await tester.pumpAndSettle();
      await tester.enterText(noteFinder, 'تم الانتهاء من بناء الدور الأول');
      await tester.pump();

      await tester.tap(find.byKey(const Key('contractor_task_update_submit')));
      await tester.pumpAndSettle();

      expect(repository.submittedUpdates, hasLength(1));
      final submitted = repository.submittedUpdates.single;
      expect(submitted.taskId, 't-1');
      expect(submitted.proposedState, TaskUpdateState.done);
      expect(submitted.photos, hasLength(1));
      expect(submitted.note, 'تم الانتهاء من بناء الدور الأول');
    },
  );

  testWidgets(
    'navigates from schedule «تحديث مهمة» button to /contractor/tasks/:projectId/updates/new',
    (tester) async {
      await pumpAppRouter(
        tester,
        session: FakeAppSession()..signIn(AppRole.contractor),
        initialLocation: '/contractor/tasks/p-1',
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('contractor_project_tasks_update')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ContractorTaskUpdatePage), findsOneWidget);
      expect(find.text('ما المهمة التي تريد تحديثها؟'), findsOneWidget);
    },
  );

  testWidgets(
    'renders Step 1 and Step 2 without overflow at 200% bold text scale',
    (tester) async {
      final bloc = buildUpdateBloc()
        ..add(const ContractorTaskUpdateFetched('p-1'));
      final cubit = ContractorTaskUpdateStepCubit();
      addTearDown(bloc.close);
      addTearDown(cubit.close);

      await pumpLocalizedApp(
        tester,
        MultiBlocProvider(
          providers: [
            BlocProvider.value(value: bloc),
            BlocProvider.value(value: cubit),
          ],
          child: ContractorTaskUpdatePage(
            projectId: 'p-1',
            now: DateTime.utc(2026, 2, 12, 12),
          ),
        ),
        textScale: largeTextScale,
        boldText: true,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const Key('contractor_task_update_next')));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
