import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/features/auth/shared/domain/entities/auth_role.dart';

part 'role_event.dart';
part 'role_state.dart';

class RoleBloc extends Bloc<RoleEvent, RoleState> {
  RoleBloc({AuthRole initialRole = AuthRole.client})
    : super(RoleSelectionState(selectedRole: initialRole)) {
    on<RoleSelected>(_onRoleSelected);
  }

  void _onRoleSelected(RoleSelected event, Emitter<RoleState> emit) {
    emit(RoleSelectionState(selectedRole: event.role));
  }
}
