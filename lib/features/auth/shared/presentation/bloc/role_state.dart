part of 'role_bloc.dart';

sealed class RoleState {
  const RoleState();
}

final class RoleSelectionState extends RoleState {
  const RoleSelectionState({this.selectedRole = AuthRole.client});

  final AuthRole selectedRole;

  RoleSelectionState copyWith({AuthRole? selectedRole}) {
    return RoleSelectionState(selectedRole: selectedRole ?? this.selectedRole);
  }
}
