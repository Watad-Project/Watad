import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/router/routes/location_routes.dart';
import 'package:watad/features/location/shared/presentation/bloc/location_bloc.dart';
import 'package:watad/features/location/shared/presentation/pages/location_page.dart';

/// Route definition for the shared location feature.
final List<RouteBase> locationRoutes = [
  GoRoute(
    name: LocationRoutes.locationName,
    path: LocationRoutes.locationPath,
    builder: (context, state) => BlocProvider(
      create: (_) => getIt<LocationBloc>(),
      child: const LocationPage(),
    ),
  ),
];
