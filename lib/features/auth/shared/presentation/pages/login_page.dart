import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/display/app_logo.dart';
import 'package:watad/core/components/feedback/app_snack_bar.dart';
import 'package:watad/core/components/inputs/app_otp_input.dart';
import 'package:watad/core/components/inputs/app_text_field.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/features/auth/shared/domain/usecases/verify_otp_use_case.dart';
import 'package:watad/features/auth/shared/presentation/bloc/auth_bloc.dart';

/// Passwordless login (/auth/login): the email, then the code sent to it.
///
/// Confirm sends the code first, then checks it. Where a signed-in user
/// goes next is decided by the router guard (APP_ARCHITECTURE.md §11).
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (_, state) =>
          state.successMessage != null || state.errorMessage != null,
      listener: (context, state) {
        if (state.successMessage case final key?) {
          context.showSuccessSnackBar(context.tr(key));
        }
        if (state.errorMessage case final key?) {
          context.showErrorSnackBar(context.tr(key));
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
                        textInputAction: TextInputAction.send,
                        errorText: state.emailError == null
                            ? null
                            : context.tr(state.emailError!),
                        onChanged: (email) => bloc.add(AuthEmailChanged(email)),
                        onSubmitted: (_) => bloc.add(const AuthOtpRequested()),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Center(
                        child: AppOtpInput(
                          length: VerifyOtpUseCase.codeLength,
                          enabled: state.codeSent && !state.isBusy,
                          errorText: state.otpError == null
                              ? null
                              : context.tr(state.otpError!),
                          onChanged: (otp) => bloc.add(AuthOtpChanged(otp)),
                          onCompleted: (_) =>
                              bloc.add(const AuthOtpSubmitted()),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      AppButton(
                        label: context.tr('auth.confirm'),
                        isLoading: state.isBusy,
                        onPressed: () => bloc.add(
                          state.codeSent
                              ? const AuthOtpSubmitted()
                              : const AuthOtpRequested(),
                        ),
                      ),
                      if (state.codeSent) ...[
                        const SizedBox(height: AppSpacing.lg),
                        _ResendHint(state: state),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      const _NewUserHint(),
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

/// "Didn't receive the code? Resend in 00:28", then a resend link.
class _ResendHint extends StatelessWidget {
  const _ResendHint({required this.state});

  final AuthState state;

  /// mm:ss, kept left to right inside Arabic text.
  static String _time(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final rest = (seconds % 60).toString().padLeft(2, '0');
    return '\u202A$minutes:$rest\u202C';
  }

  @override
  Widget build(BuildContext context) {
    final caption = AppTextStyles.caption.copyWith(
      color: AppColors.textSecondary,
    );
    if (!state.canResend) {
      return Text(
        context.tr(
          'auth.resend_countdown',
          namedArgs: {'time': _time(state.resendSeconds)},
        ),
        style: caption,
        textAlign: TextAlign.center,
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(context.tr('auth.resend_prefix'), style: caption),
        const SizedBox(width: AppSpacing.xs),
        GestureDetector(
          onTap: () => context.read<AuthBloc>().add(const AuthOtpRequested()),
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
}

/// "New user? Create an account".
class _NewUserHint extends StatelessWidget {
  const _NewUserHint();

  @override
  Widget build(BuildContext context) {
    // GRA-11 adds the role selection route (/auth/role) to AuthRoutes and
    // makes "Create an account" open it.
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          context.tr('auth.new_user'),
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          context.tr('auth.create_account'),
          style: AppTextStyles.caption.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
