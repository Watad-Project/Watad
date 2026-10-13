import 'package:get_it/get_it.dart';
import 'package:watad/features/projects/client/presentation/bloc/client_post_project_bloc.dart';

/// Registers the types of lib/features/projects/client/ into [getIt].
///
/// Called once during app bootstrap from lib/core/di/injection.dart.
void registerClientProjectsDependencies(GetIt getIt) {
  getIt.registerFactory<ClientPostProjectBloc>(() {
    return ClientPostProjectBloc();
  });
}
