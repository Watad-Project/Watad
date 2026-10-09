import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
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

/// Passwordless login screen with email OTP (/auth/login).
///
/// The user enters an email address and the verification code sent to that email.
/// Features a live countdown timer for resending the code, validation, and
/// navigation to registration (/auth/role).
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const int _resendCooldownSeconds = 28;
  static final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$',
  );

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _otpFocusNode = FocusNode();

  Timer? _countdownTimer;
  int _resendSeconds = _resendCooldownSeconds;
  bool _isLoading = false;
  String? _emailError;
  String? _otpError;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _emailController.dispose();
    _otpController.dispose();
    _emailFocusNode.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _resendSeconds = _resendCooldownSeconds);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSeconds > 0) {
        setState(() => _resendSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  void _onResend() {
    if (_resendSeconds > 0) return;
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _emailError = context.tr('auth.email_required_error'));
      _emailFocusNode.requestFocus();
      return;
    }
    if (!_emailRegExp.hasMatch(email)) {
      setState(() => _emailError = context.tr('auth.invalid_email_error'));
      _emailFocusNode.requestFocus();
      return;
    }

    _startCountdown();
    context.showSnackBar(context.tr('auth.otp_sent_success'));
  }

  void _onConfirm() {
    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();

    String? emailErr;
    String? otpErr;

    if (email.isEmpty) {
      emailErr = context.tr('auth.email_required_error');
    } else if (!_emailRegExp.hasMatch(email)) {
      emailErr = context.tr('auth.invalid_email_error');
    }

    if (otp.isEmpty) {
      otpErr = context.tr('auth.otp_required_error');
    } else if (otp.length < AppOtpInput.defaultLength) {
      otpErr = context.tr('auth.invalid_otp_error');
    }

    setState(() {
      _emailError = emailErr;
      _otpError = otpErr;
    });

    if (emailErr != null) {
      _emailFocusNode.requestFocus();
      return;
    }
    if (otpErr != null) {
      _otpFocusNode.requestFocus();
      return;
    }

    setState(() => _isLoading = true);
    Timer(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }

  String _formatSeconds(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '\u202A$minutes:$seconds\u202C';
  }

  @override
  Widget build(BuildContext context) {
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
                    controller: _emailController,
                    focusNode: _emailFocusNode,
                    label: context.tr('auth.email_label'),
                    hint: context.tr('auth.email_hint'),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    errorText: _emailError,
                    onChanged: (val) {
                      if (_emailError != null) {
                        setState(() => _emailError = null);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Center(
                    child: AppOtpInput(
                      controller: _otpController,
                      focusNode: _otpFocusNode,
                      length: AppOtpInput.defaultLength,
                      errorText: _otpError,
                      onChanged: (val) {
                        if (_otpError != null) {
                          setState(() => _otpError = null);
                        }
                      },
                      onCompleted: (_) => _onConfirm(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppButton(
                    label: context.tr('auth.confirm'),
                    onPressed: _onConfirm,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildResendSection(context),
                  const SizedBox(height: AppSpacing.md),
                  _buildNewUserLink(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResendSection(BuildContext context) {
    if (_resendSeconds > 0) {
      final formattedTime = _formatSeconds(_resendSeconds);
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
          onTap: _onResend,
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
