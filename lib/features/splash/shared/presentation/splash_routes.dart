import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/router/routes/splash_routes.dart';
import 'package:watad/features/splash/shared/presentation/bloc/splash_bloc.dart';
import 'package:watad/features/splash/shared/presentation/pages/splash_page.dart';

final List<RouteBase> splashRoutes = [
  GoRoute(
    name: SplashRoutes.splashName,
    path: SplashRoutes.splashPath,
    builder: (context, state) => BlocProvider(
      create: (_) => getIt<SplashBloc>()..add(const SplashStarted()),
      child: const SplashPage(),
    ),
  ),
];
