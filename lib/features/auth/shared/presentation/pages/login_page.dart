import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/display/app_logo.dart';
import 'package:watad/core/components/feedback/app_snack_bar.dart';
import 'package:watad/core/components/inputs/app_otp_input.dart';
import 'package:watad/core/components/inputs/app_text_field.dart';
import 'package:watad/core/router/app_routes.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/features/auth/shared/presentation/bloc/auth_bloc.dart';

/// Passwordless login screen with email OTP (/auth/login).
///
/// Implemented as a [StatelessWidget] driven entirely by [AuthBloc].
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  String _formatSeconds(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '\u202A$minutes:$seconds\u202C';
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          current.message != null || current.status == AuthStatus.verified,
      listener: (context, state) {
        if (state.message != null) {
          context.showSnackBar(context.tr(state.message!));
        }
        if (state.status == AuthStatus.verified) {
          context.pushNamed(AppRoutes.roleSelectionName);
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.surface,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.xxl,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(child: AppLogo(height: 72)),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        context.tr('auth.login_title'),
                        style: AppTextStyles.h1,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        context.tr('auth.login_subtitle'),
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      AppTextField(
                        label: context.tr('auth.email_label'),
                        hint: context.tr('auth.email_hint'),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        errorText: state.emailError != null
                            ? context.tr(state.emailError!)
                            : null,
                        onChanged: (val) =>
                            context.read<AuthBloc>().add(AuthEmailChanged(val)),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Center(
                        child: AppOtpInput(
                          length: AppOtpInput.defaultLength,
                          errorText: state.otpError != null
                              ? context.tr(state.otpError!)
                              : null,
                          onChanged: (val) =>
                              context.read<AuthBloc>().add(AuthOtpChanged(val)),
                          onCompleted: (_) => context.read<AuthBloc>().add(
                            const AuthOtpSubmitted(),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      AppButton(
                        label: context.tr('auth.confirm'),
                        onPressed: () => context.read<AuthBloc>().add(
                          const AuthOtpSubmitted(),
                        ),
                        isLoading: state.isLoading,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _buildResendSection(context, state),
                      const SizedBox(height: AppSpacing.md),
                      _buildNewUserLink(context),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildResendSection(BuildContext context, AuthState state) {
    if (state.resendSeconds > 0) {
      final formattedTime = _formatSeconds(state.resendSeconds);
      return Text(
        context.tr('auth.resend_countdown', namedArgs: {'time': formattedTime}),
        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        textAlign: TextAlign.center,
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          context.tr('auth.resend_prefix'),
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(width: AppSpacing.xs),
        GestureDetector(
          onTap: () =>
              context.read<AuthBloc>().add(const AuthResendRequested()),
          child: Text(
            context.tr('auth.resend_code'),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNewUserLink(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          context.tr('auth.new_user'),
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(width: AppSpacing.xs),
        GestureDetector(
          onTap: () => context.pushNamed(AppRoutes.roleSelectionName),
          child: Text(
            context.tr('auth.create_account'),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
