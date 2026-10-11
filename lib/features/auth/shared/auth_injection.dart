import 'package:get_it/get_it.dart';
import 'package:watad/features/auth/shared/presentation/bloc/role_bloc.dart';

/// Registers dependencies for lib/features/auth/shared/.
void registerAuthDependencies(GetIt getIt) {
  getIt.registerFactory(() {
    return RoleBloc();
  });
}
