import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/feedback/app_error_view.dart';
import 'package:watad/core/components/feedback/app_loading_indicator.dart';
import 'package:watad/core/components/feedback/app_snack_bar.dart';
import 'package:watad/core/router/routes/profile_routes.dart';
import 'package:watad/core/theme/app_motion.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/features/profile/shared/domain/entities/my_profile_business.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_overview.dart';
import 'package:watad/features/profile/shared/presentation/bloc/profile_overview_bloc.dart';
import 'package:watad/features/profile/shared/presentation/widgets/profile_header.dart';
import 'package:watad/features/profile/shared/presentation/widgets/profile_menu.dart';
import 'package:watad/features/profile/shared/presentation/widgets/profile_suspension_banner.dart';

/// The account tab of every role (GRA-59): the suspension banner, the
/// header, the business part ([businessBuilder], for a contractor) and the
/// menu. Pull to refresh reloads it; while it reloads, or when reloading
/// fails, what's on screen stays.
class ProfileOverviewBody extends StatelessWidget {
  const ProfileOverviewBody({this.businessBuilder, super.key});

  /// Builds the part under the header for a business: «منشأتي» passes its
  /// business card. Null for the client's «حسابي».
  final Widget Function(MyProfileBusiness business)? businessBuilder;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ProfileOverviewBloc>();
    return BlocConsumer<ProfileOverviewBloc, ProfileOverviewState>(
      // Reloading failed while the profile is on screen: say so, keep it.
      listenWhen: (previous, current) =>
          current.status == ProfileOverviewStatus.failure &&
          previous.status != ProfileOverviewStatus.failure &&
          current.overview != null,
      listener: (context, state) {
        if (state.failure case final failure?) {
          context.showErrorSnackBar(
            context.tr(failure.messageKey),
            onRetry: () => bloc.add(const ProfileOverviewFetched()),
          );
        }
      },
      // Loading, the profile and errors fade into each other.
      builder: (context, state) => AnimatedSwitcher(
        duration: AppMotion.enter,
        reverseDuration: AppMotion.exit,
        switchInCurve: AppMotion.enterCurve,
        switchOutCurve: AppMotion.exitCurve,
        child: switch (state) {
          ProfileOverviewState(:final overview?) => _ProfileOverviewContent(
            key: const ValueKey('profile'),
            overview: overview,
            businessBuilder: businessBuilder,
          ),
          ProfileOverviewState(
            status: ProfileOverviewStatus.failure,
            :final failure?,
          ) =>
            AppErrorView(
              key: const ValueKey('error'),
              message: context.tr(failure.messageKey),
              onRetry: () => bloc.add(const ProfileOverviewFetched()),
            ),
          _ => const AppLoadingIndicator(key: ValueKey('loading')),
        },
      ),
    );
  }
}

class _ProfileOverviewContent extends StatelessWidget {
  const _ProfileOverviewContent({
    required this.overview,
    this.businessBuilder,
    super.key,
  });

  final ProfileOverview overview;
  final Widget Function(MyProfileBusiness business)? businessBuilder;

  @override
  Widget build(BuildContext context) {
    final profile = overview.profile;
    final business = profile.business;
    final buildBusiness = businessBuilder;
    return RefreshIndicator(
      // The spinner stays until the new profile arrives.
      onRefresh: () {
        final bloc = context.read<ProfileOverviewBloc>()
          ..add(const ProfileOverviewFetched());
        return bloc.stream.first;
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsetsDirectional.all(AppSpacing.md),
        children: [
          if (profile.isSuspended) ...[
            ProfileSuspensionBanner(reason: profile.suspensionReason),
            const SizedBox(height: AppSpacing.md),
          ],
          ProfileHeader(profile: profile, rating: overview.rating),
          if (business != null && buildBusiness != null) ...[
            const SizedBox(height: AppSpacing.lg),
            buildBusiness(business),
          ],
          const SizedBox(height: AppSpacing.lg),
          ProfileMenu(
            isSuspended: profile.isSuspended,
            onEditProfile: () => _editProfile(context),
          ),
        ],
      ),
    );
  }

  /// Opens the edit profile page (GRA-60), then reloads: a saved name,
  /// photo or business changes what the tab shows.
  Future<void> _editProfile(BuildContext context) async {
    final bloc = context.read<ProfileOverviewBloc>();
    await context.pushNamed(ProfileRoutes.profileEditName);
    bloc.add(const ProfileOverviewFetched());
  }
}
