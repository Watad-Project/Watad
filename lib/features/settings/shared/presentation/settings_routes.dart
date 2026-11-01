import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/router/routes/settings_routes.dart';
import 'package:watad/features/settings/shared/presentation/bloc/settings_bloc.dart';
import 'package:watad/features/settings/shared/presentation/pages/settings_info_page.dart';
import 'package:watad/features/settings/shared/presentation/pages/settings_page.dart';

final List<RouteBase> settingsRoutes = [
  GoRoute(
    name: SettingsRoutes.settingsName,
    path: SettingsRoutes.settingsPath,
    builder: (context, state) => BlocProvider(
      create: (_) => getIt<SettingsBloc>()..add(const SettingsFetched()),
      child: const SettingsPage(),
    ),
  ),
  GoRoute(
    name: SettingsRoutes.settingsInfoName,
    path: SettingsRoutes.settingsInfoPath,
    builder: (context, state) =>
        SettingsInfoPage(page: state.pathParameters['page']!),
  ),
];
