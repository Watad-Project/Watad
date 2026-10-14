import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/layout/app_action_bar.dart';
import 'package:watad/core/components/layout/app_top_bar.dart';
import 'package:watad/core/router/routes/auth_routes.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/features/auth/shared/domain/entities/auth_role.dart';
import 'package:watad/features/auth/shared/presentation/bloc/role_bloc.dart';
import 'package:watad/features/auth/shared/presentation/widgets/role_card.dart';

class RolePage extends StatelessWidget {
  const RolePage({super.key, this.onContinue, this.onBack});

  /// Called when the user confirms their selection.
  ///
  /// Passes the chosen [AuthRole] along so the caller can navigate to
  /// `/auth/signup/client` or `/auth/signup/business`.
  final void Function(BuildContext context, AuthRole role)? onContinue;

  /// Optional back callback.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoleBloc, RoleState>(
      builder: (context, state) {
        final selectedRole = state is RoleSelectionState
            ? state.selectedRole
            : AuthRole.client;

        final canPop = Navigator.of(context).canPop();

        return Scaffold(
          backgroundColor: AppColors.surface,
          appBar: AppTopBar(
            title: '',
            onBack:
                onBack ?? (canPop ? () => Navigator.of(context).pop() : null),
          ),
          bottomNavigationBar: AppActionBar(
            primary: AppButton(
              label: context.tr('auth.continue'),
              onPressed: () {
                if (onContinue != null) {
                  onContinue?.call(context, selectedRole);
                } else if (selectedRole == AuthRole.contractor) {
                  context.goNamed(AuthRoutes.signUpBusinessName);
                }
              },
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.md),
                  Text(context.tr('auth.role_title'), style: AppTextStyles.h1),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    context.tr('auth.role_subtitle'),
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  RoleCard(
                    title: context.tr('auth.role_client_title'),
                    description: context.tr('auth.role_client_description'),
                    note: context.tr('auth.role_client_note'),
                    icon: Icons.person_outline,
                    selected: selectedRole == AuthRole.client,
                    onTap: () {
                      context.read<RoleBloc>().add(
                        const RoleSelected(AuthRole.client),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  RoleCard(
                    title: context.tr('auth.role_contractor_title'),
                    description: context.tr('auth.role_contractor_description'),
                    note: context.tr('auth.role_contractor_note'),
                    icon: Icons.business_outlined,
                    selected: selectedRole == AuthRole.contractor,
                    onTap: () {
                      context.read<RoleBloc>().add(
                        const RoleSelected(AuthRole.contractor),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
