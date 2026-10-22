import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/feedback/app_confirm_dialog.dart';
import 'package:watad/core/components/feedback/app_empty_view.dart';
import 'package:watad/core/components/feedback/app_error_view.dart';
import 'package:watad/core/components/feedback/app_snack_bar.dart';
import 'package:watad/core/components/feedback/app_status_card.dart';
import 'package:watad/core/components/layout/app_top_bar.dart';
import 'package:watad/core/enums/user_role.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/router/routes/admin_navigation_routes.dart';
import 'package:watad/core/router/routes/admin_review_routes.dart';
import 'package:watad/core/theme/app_motion.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/core/theme/app_tone.dart';
import 'package:watad/features/users/admin/domain/entities/admin_user.dart';
import 'package:watad/features/users/admin/presentation/bloc/admin_user_details_bloc.dart';
import 'package:watad/features/users/admin/presentation/widgets/admin_user_profile.dart';
import 'package:watad/features/users/admin/presentation/widgets/admin_users_labels.dart';
import 'package:watad/features/users/admin/presentation/widgets/admin_users_skeleton.dart';

/// One user's page: their account, business and activity, their
/// suspension, and the actions that apply to them. A closed account is
/// read-only.
class AdminUserDetailsPage extends StatelessWidget {
  const AdminUserDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(
        title: context.tr('users.details_title'),
        onBack: () => context.pop(),
      ),
      body: BlocConsumer<AdminUserDetailsBloc, AdminUserDetailsState>(
        listenWhen: (previous, current) =>
            current.message != null && previous.message != current.message,
        listener: (context, state) {
          final message = state.message!;
          if (message.isError) {
            context.showErrorSnackBar(context.tr(message.key));
          } else {
            context.showSuccessSnackBar(context.tr(message.key));
          }
        },
        // Loading, the user and errors fade into each other.
        builder: (context, state) => AnimatedSwitcher(
          duration: AppMotion.enter,
          reverseDuration: AppMotion.exit,
          switchInCurve: AppMotion.enterCurve,
          switchOutCurve: AppMotion.exitCurve,
          child: _body(context, state),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, AdminUserDetailsState state) {
    final bloc = context.read<AdminUserDetailsBloc>();
    final user = state.user;
    if (user == null) {
      return switch (state.failure) {
        NotFoundFailure() => AppEmptyView(
          key: const ValueKey('not_found'),
          message: context.tr('users.not_found'),
          icon: Icons.person_off_outlined,
        ),
        final failure? => AppErrorView(
          key: const ValueKey('error'),
          message: context.tr(failure.messageKey),
          onRetry: () {
            if (state.userId case final id?) {
              bloc.add(AdminUserDetailsFetched(id));
            }
          },
        ),
        null => const Padding(
          key: ValueKey('loading'),
          padding: EdgeInsetsDirectional.all(AppSpacing.md),
          child: AdminUsersSkeleton(),
        ),
      };
    }
    return ListView(
      key: const ValueKey('user'),
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      children: [
        AdminUserProfile(
          user: user,
          now: DateTime.now(),
          onCopied: (_) =>
              context.showSuccessSnackBar(context.tr('users.copied')),
          onOpenReview: () => context.goNamed(
            AdminNavigationRoutes.navigationName,
            queryParameters: {'tab': AdminReviewRoutes.reviewName},
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (user.isSuspended) ...[
          AppStatusCard(
            tone: AppTone.danger,
            title: context.tr('users.suspended'),
            subtitle: _suspendedSince(context, user),
            reasonTitle: context.tr('common.reason'),
            reasonText: user.suspensionReason,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (user.isDeleted)
          AppStatusCard(
            tone: AppTone.neutral,
            title: context.tr('users.closed'),
            subtitle: context.tr('users.closed_read_only'),
          )
        else
          _Actions(user: user, isBusy: state.isBusy, bloc: bloc),
      ],
    );
  }

  /// «منذ ٢٢ أكتوبر ٢٠٢٦، بواسطة عمر».
  static String? _suspendedSince(BuildContext context, AdminUser user) {
    final since = user.suspendedAt;
    if (since == null) return null;
    final date = AdminUsersLabels.date(context, since);
    final by = user.suspendedByName;
    return by == null
        ? context.tr('users.suspended_since', args: [date])
        : context.tr('users.suspended_since_by', args: [date, by]);
  }
}

/// The actions that apply to this user; the others are hidden, with a line
/// saying why when it isn't obvious.
class _Actions extends StatelessWidget {
  const _Actions({
    required this.user,
    required this.isBusy,
    required this.bloc,
  });

  final AdminUser user;
  final bool isBusy;
  final AdminUserDetailsBloc bloc;

  @override
  Widget build(BuildContext context) {
    final buttons = <Widget>[
      if (user.canBeSuspended)
        AppButton(
          label: context.tr('users.suspend'),
          variant: AppButtonVariant.dark,
          isLoading: isBusy,
          onPressed: isBusy ? null : () => _suspend(context),
        ),
      if (user.canBeUnsuspended)
        AppButton(
          label: context.tr('users.unsuspend'),
          variant: AppButtonVariant.dark,
          isLoading: isBusy,
          onPressed: isBusy ? null : () => _unsuspend(context),
        ),
      if (user.canChangeRole)
        AppButton(
          label: context.tr(
            user.isAdmin ? 'users.remove_admin' : 'users.make_admin',
          ),
          variant: AppButtonVariant.secondary,
          onPressed: isBusy ? null : () => _changeRole(context),
        ),
    ];
    final note = switch (user) {
      _ when user.isMe => 'users.note_you',
      _ when user.isAdmin && !user.isSuspended => 'users.note_admin',
      _ => null,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, button) in buttons.indexed) ...[
          if (index > 0) const SizedBox(height: AppSpacing.sm),
          button,
        ],
        if (note != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(context.tr(note), style: AppTextStyles.caption),
        ],
      ],
    );
  }

  Future<void> _suspend(BuildContext context) async {
    final reason = await AppConfirmDialog.show(
      context,
      title: context.tr('users.suspend_title'),
      message: context.tr('users.suspend_message'),
      confirmLabel: context.tr('users.suspend'),
      reasonLabel: context.tr('common.reason'),
    );
    if (reason != null) bloc.add(AdminUserSuspended(reason));
  }

  Future<void> _unsuspend(BuildContext context) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: context.tr('users.unsuspend_title'),
      message: context.tr('users.unsuspend_message'),
      confirmLabel: context.tr('users.unsuspend'),
    );
    if (confirmed != null) bloc.add(const AdminUserUnsuspended());
  }

  Future<void> _changeRole(BuildContext context) async {
    final makeAdmin = !user.isAdmin;
    final confirmed = await AppConfirmDialog.show(
      context,
      title: context.tr(
        makeAdmin ? 'users.make_admin_title' : 'users.remove_admin_title',
      ),
      message: context.tr(
        makeAdmin ? 'users.make_admin_message' : 'users.remove_admin_message',
      ),
      confirmLabel: context.tr(
        makeAdmin ? 'users.make_admin' : 'users.remove_admin',
      ),
    );
    if (confirmed == null) return;
    bloc.add(AdminUserRoleChanged(makeAdmin ? UserRole.admin : UserRole.user));
  }
}
