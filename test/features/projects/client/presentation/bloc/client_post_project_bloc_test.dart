import 'package:flutter_test/flutter_test.dart';
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
