part of 'role_bloc.dart';

sealed class RoleEvent {
  const RoleEvent();
}

final class RoleSelected extends RoleEvent {
  const RoleSelected(this.role);

  final AuthRole role;
}
