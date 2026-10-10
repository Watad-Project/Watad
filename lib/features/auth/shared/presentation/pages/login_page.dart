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
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  static String _formatTime(int sec) =>
      '\u202A${(sec ~/ 60).toString().padLeft(2, '0')}:${(sec % 60).toString().padLeft(2, '0')}\u202C';

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (_, curr) =>
          curr.message != null || curr.status == AuthStatus.verified,
      listener: (context, state) {
        if (state.message != null) {
          context.showSnackBar(context.tr(state.message!));
        }
        if (state.status == AuthStatus.verified) {
          context.pushNamed(AppRoutes.roleSelectionName);
        }
      },
      builder: (context, state) {
        final bloc = context.read<AuthBloc>();
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
                        onChanged: (v) => bloc.add(AuthEmailChanged(v)),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Center(
                        child: AppOtpInput(
                          length: AppOtpInput.defaultLength,
                          errorText: state.otpError != null
                              ? context.tr(state.otpError!)
                              : null,
                          onChanged: (v) => bloc.add(AuthOtpChanged(v)),
                          onCompleted: (_) =>
                              bloc.add(const AuthOtpSubmitted()),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      AppButton(
                        label: context.tr('auth.confirm'),
                        onPressed: () => bloc.add(const AuthOtpSubmitted()),
                        isLoading: state.isLoading,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      if (state.resendSeconds > 0)
                        Text(
                          context.tr(
                            'auth.resend_countdown',
                            namedArgs: {
                              'time': _formatTime(state.resendSeconds),
                            },
                          ),
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        )
                      else
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              context.tr('auth.resend_prefix'),
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            GestureDetector(
                              onTap: () =>
                                  bloc.add(const AuthResendRequested()),
                              child: Text(
                                context.tr('auth.resend_code'),
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            context.tr('auth.new_user'),
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          GestureDetector(
                            onTap: () =>
                                context.pushNamed(AppRoutes.roleSelectionName),
                            child: Text(
                              context.tr('auth.create_account'),
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
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
}
