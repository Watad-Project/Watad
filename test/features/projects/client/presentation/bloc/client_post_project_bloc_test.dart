import 'package:flutter_test/flutter_test.dart';
import 'package:watad/features/projects/client/domain/entities/client_deed_verification_status.dart';
import 'package:watad/features/projects/client/domain/entities/client_project_type.dart';
import 'package:watad/features/projects/client/presentation/bloc/client_post_project_bloc.dart';

void main() {
  group('ClientPostProjectBloc', () {
    test('initial state defaults to step 1 and no selected type', () {
      final bloc = ClientPostProjectBloc();
      expect(bloc.state.currentStep, 1);
      expect(bloc.state.projectType, isNull);
      expect(bloc.state.status, ClientPostProjectStatus.initial);
      expect(bloc.state.canProceedFromStep1, isFalse);
      expect(bloc.state.canProceedFromStep2, isFalse);
      bloc.close();
    });

    test('selects newHouse type with deed required and 4 steps', () async {
      final bloc = ClientPostProjectBloc();

      bloc.add(const ClientPostProjectTypeSelected(ClientProjectType.newHouse));
      await expectLater(
        bloc.stream,
        emits(
          predicate<ClientPostProjectState>((s) {
            return s.projectType == ClientProjectType.newHouse &&
                s.requiresDeed == true &&
                s.totalSteps == 4 &&
                s.canProceedFromStep1 == true;
          }),
        ),
      );

      await bloc.close();
    });

    test('selects repairs type without deed and 3 steps', () async {
      final bloc = ClientPostProjectBloc();

      bloc.add(const ClientPostProjectTypeSelected(ClientProjectType.repairs));
      await expectLater(
        bloc.stream,
        emits(
          predicate<ClientPostProjectState>((s) {
            return s.projectType == ClientProjectType.repairs &&
                s.requiresDeed == false &&
                s.totalSteps == 3 &&
                s.canProceedFromStep1 == true;
          }),
        ),
      );

      await bloc.close();
    });

    test('handles step 2 fields and validation', () async {
      final bloc = ClientPostProjectBloc();

      bloc.add(const ClientPostProjectTypeSelected(ClientProjectType.newHouse));
      bloc.add(const ClientPostProjectScopeChanged('House foundation work'));
      bloc.add(const ClientPostProjectMinBudgetChanged(50000));
      bloc.add(const ClientPostProjectMaxBudgetChanged(100000));
      bloc.add(const ClientPostProjectLocationChanged('Riyadh Al-Morouj'));
      bloc.add(const ClientPostProjectPhotoAdded('photo1.jpg'));

      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<ClientPostProjectState>((s) {
            return s.scopeOfWork == 'House foundation work' &&
                s.minBudget == 50000 &&
                s.maxBudget == 100000 &&
                s.locationAddress == 'Riyadh Al-Morouj' &&
                s.photos.length == 1 &&
                s.canProceedFromStep2 == true &&
                s.isBudgetValid == true;
          }),
        ),
      );

      bloc.add(const ClientPostProjectPhotoRemoved(0));
      await expectLater(
        bloc.stream,
        emits(predicate<ClientPostProjectState>((s) => s.photos.isEmpty)),
      );

      await bloc.close();
    });

    test('invalidates budget when max is less than min', () async {
      final bloc = ClientPostProjectBloc();

      bloc.add(const ClientPostProjectMinBudgetChanged(100000));
      bloc.add(const ClientPostProjectMaxBudgetChanged(50000));

      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<ClientPostProjectState>((s) {
            return s.isBudgetValid == false && s.canProceedFromStep2 == false;
          }),
        ),
      );

      await bloc.close();
    });

    test('advances and retreats between steps', () async {
      final bloc = ClientPostProjectBloc();

      bloc.add(
        const ClientPostProjectTypeSelected(ClientProjectType.renovation),
      );
      bloc.add(const ClientPostProjectStepAdvanced());
      bloc.add(const ClientPostProjectStepRetreated());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<ClientPostProjectState>((s) => s.currentStep == 1),
          predicate<ClientPostProjectState>((s) => s.currentStep == 2),
          predicate<ClientPostProjectState>((s) => s.currentStep == 1),
        ]),
      );

      await bloc.close();
    });

    test('handles step 3 deed upload and review lifecycle', () async {
      final bloc = ClientPostProjectBloc();

      bloc.add(const ClientPostProjectTypeSelected(ClientProjectType.newHouse));
      expect(bloc.state.deedStatus, ClientDeedVerificationStatus.none);
      expect(bloc.state.canProceedFromStep3, isFalse);

      bloc.add(
        const ClientPostProjectDeedSelected(
          filePath: 'path/to/deed.pdf',
          fileName: 'my_deed.pdf',
        ),
      );

      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<ClientPostProjectState>((s) {
            return s.deedFilePath == 'path/to/deed.pdf' &&
                s.deedFileName == 'my_deed.pdf' &&
                s.deedStatus == ClientDeedVerificationStatus.underReview &&
                s.canProceedFromStep3 == true;
          }),
        ),
      );

      bloc.add(
        const ClientPostProjectDeedStatusChanged(
          ClientDeedVerificationStatus.verified,
        ),
      );

      await expectLater(
        bloc.stream,
        emits(
          predicate<ClientPostProjectState>((s) {
            return s.deedStatus == ClientDeedVerificationStatus.verified &&
                s.canProceedFromStep3 == true;
          }),
        ),
      );

      bloc.add(
        const ClientPostProjectDeedStatusChanged(
          ClientDeedVerificationStatus.rejected,
          rejectionReason: 'مرفوض — اسم المالك لا يطابق الهوية',
        ),
      );

      await expectLater(
        bloc.stream,
        emits(
          predicate<ClientPostProjectState>((s) {
            return s.deedStatus == ClientDeedVerificationStatus.rejected &&
                s.deedRejectionReason == 'مرفوض — اسم المالك لا يطابق الهوية';
          }),
        ),
      );

      bloc.add(const ClientPostProjectDeedRetry());

      await expectLater(
        bloc.stream,
        emits(
          predicate<ClientPostProjectState>((s) {
            return s.deedFilePath == null &&
                s.deedFileName == null &&
                s.deedStatus == ClientDeedVerificationStatus.none &&
                s.deedRejectionReason == null &&
                s.canProceedFromStep3 == false;
          }),
        ),
      );

      await bloc.close();
    });

    test('resets back to initial state', () async {
      final bloc = ClientPostProjectBloc();

      bloc.add(const ClientPostProjectTypeSelected(ClientProjectType.newHouse));
      bloc.add(const ClientPostProjectReset());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<ClientPostProjectState>(
            (s) => s.projectType == ClientProjectType.newHouse,
          ),
          predicate<ClientPostProjectState>(
            (s) => s.projectType == null && s.currentStep == 1,
          ),
        ]),
      );

      await bloc.close();
    });
  });
}
