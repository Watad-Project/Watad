import 'package:flutter_test/flutter_test.dart';
import 'package:watad/features/auth/shared/domain/entities/auth_role.dart';
import 'package:watad/features/auth/shared/presentation/bloc/role_bloc.dart';

void main() {
  test('initial state defaults to client role', () {
    final bloc = RoleBloc();
    expect(bloc.state, isA<RoleSelectionState>());
    expect((bloc.state as RoleSelectionState).selectedRole, AuthRole.client);
    bloc.close();
  });

  test('emits new state when RoleSelected is added', () async {
    final bloc = RoleBloc();
    final states = expectLater(
      bloc.stream,
      emitsInOrder([
        predicate<RoleState>(
          (s) =>
              s is RoleSelectionState && s.selectedRole == AuthRole.contractor,
        ),
        predicate<RoleState>(
          (s) => s is RoleSelectionState && s.selectedRole == AuthRole.client,
        ),
      ]),
    );

    bloc.add(const RoleSelected(AuthRole.contractor));
    bloc.add(const RoleSelected(AuthRole.client));
    await states;
    await bloc.close();
  });
}
