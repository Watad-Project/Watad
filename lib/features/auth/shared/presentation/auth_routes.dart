import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/router/routes/auth_routes.dart';
import 'package:watad/features/auth/shared/presentation/bloc/sign_up_client_bloc.dart';
import 'package:watad/features/auth/shared/presentation/pages/sign_up_client_page.dart';

final List<RouteBase> authRoutes = [
  GoRoute(
    name: AuthRoutes.signUpClientName,
    path: AuthRoutes.signUpClientPath,
    builder: (context, state) => BlocProvider(
      create: (_) => getIt<SignUpClientBloc>(),
      child: const SignUpClientPage(),
    ),
  ),
];
