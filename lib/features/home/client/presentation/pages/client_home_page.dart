import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/feedback/app_error_view.dart';
import 'package:watad/core/router/routes/client_home_routes.dart';
import 'package:watad/core/router/routes/client_projects_routes.dart';
import 'package:watad/core/theme/app_motion.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/features/home/client/presentation/bloc/client_home_bloc.dart';
import 'package:watad/features/home/client/presentation/widgets/client_home_greeting_header.dart';
import 'package:watad/features/home/client/presentation/widgets/client_home_skeleton.dart';
import 'package:watad/features/home/client/presentation/widgets/client_post_project_banner.dart';
import 'package:watad/features/home/client/presentation/widgets/client_search_bar.dart';
import 'package:watad/features/home/client/presentation/widgets/client_suggested_contractors_section.dart';

/// «الرئيسية»: the first screen a client sees after signing in.
class ClientHomePage extends StatelessWidget {
  const ClientHomePage({super.key, this.bell});

  /// The notifications bell, beside the greeting.
  final Widget? bell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<ClientHomeBloc, ClientHomeState>(
          // Loading, the page and errors fade into each other.
          builder: (context, state) => AnimatedSwitcher(
            duration: AppMotion.enter,
            reverseDuration: AppMotion.exit,
            switchInCurve: AppMotion.enterCurve,
            switchOutCurve: AppMotion.exitCurve,
            child: _body(context, state),
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, ClientHomeState state) {
    final bloc = context.read<ClientHomeBloc>();
    final profile = state.profile;
    if (profile == null) {
      if (state.status == ClientHomeStatus.failure) {
        return AppErrorView(
          key: const ValueKey('error'),
          message: context.tr(state.failure!.messageKey),
          onRetry: () => bloc.add(const ClientHomeStarted()),
        );
      }
      return const ClientHomeSkeleton(key: ValueKey('loading'));
    }
    return RefreshIndicator(
      key: const ValueKey('home'),
      onRefresh: () async => bloc.add(const ClientHomeRefreshed()),
      child: ListView(
        padding: const EdgeInsetsDirectional.all(AppSpacing.md),
        children: [
          ClientHomeGreetingHeader(
            profile: profile,
            now: DateTime.now(),
            bell: bell,
          ),
          const SizedBox(height: AppSpacing.lg),
          const ClientSearchBar(),
          const SizedBox(height: AppSpacing.lg),
          ClientPostProjectBanner(
            onStart: () =>
                context.pushNamed(ClientProjectsRoutes.postProjectName),
          ),
          const SizedBox(height: AppSpacing.xl),
          ClientSuggestedContractorsSection(
            status: state.contractorsStatus,
            contractors: state.contractors,
            failureMessage: state.contractorsFailure == null
                ? null
                : context.tr(state.contractorsFailure!.messageKey),
            onRetry: () => bloc.add(const ClientHomeContractorsRetried()),
            onViewAll: () =>
                context.pushNamed(ClientHomeRoutes.contractorsName),
          ),
        ],
      ),
    );
  }
}
