import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/feedback/app_snack_bar.dart';
import 'package:watad/core/components/inputs/app_checkbox.dart';
import 'package:watad/core/components/inputs/app_otp_input.dart';
import 'package:watad/core/components/inputs/app_phone_field.dart';
import 'package:watad/core/components/inputs/app_text_field.dart';
import 'package:watad/core/components/layout/app_top_bar.dart';
import 'package:watad/core/router/routes/auth_routes.dart';
import 'package:watad/core/router/routes/client_navigation_routes.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/features/auth/shared/presentation/bloc/sign_up_client_bloc.dart';

class SignUpClientPage extends StatefulWidget {
  const SignUpClientPage({super.key});

  @override
  State<SignUpClientPage> createState() => _SignUpClientPageState();
}

class _SignUpClientPageState extends State<SignUpClientPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _nationalIdController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TapGestureRecognizer _termsRecognizer;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _nationalIdController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () {
        context.showSnackBar(context.tr('auth.coming_soon'));
      };
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _nameController.dispose();
    _nationalIdController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SignUpClientBloc, SignUpClientState>(
      listenWhen: (previous, current) =>
          previous.generalError != current.generalError ||
          previous.status != current.status,
      listener: (context, state) {
        if (state.generalError != null) {
          context.showErrorSnackBar(context.tr(state.generalError!));
        }
        if (state.status == SignUpClientStatus.success) {
          context.showSuccessSnackBar(
            context.tr(state.successMessage ?? 'auth.signup_success'),
          );
          context.goNamed(ClientNavigationRoutes.navigationName);
        }
      },
      builder: (context, state) {
        final bloc = context.read<SignUpClientBloc>();
        final isOtp = state.step == SignUpClientStep.otp;

        return Scaffold(
          appBar: AppTopBar(
            title: context.tr('auth.client_signup_header'),
            onBack: () {
              if (isOtp) {
                bloc.add(const SignUpClientStepBack());
              } else if (context.canPop()) {
                context.pop();
              } else {
                context.goNamed(AuthRoutes.roleName);
              }
            },
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.md,
              ),
              child: isOtp
                  ? _OtpSection(state: state, bloc: bloc)
                  : _FormSection(
                      state: state,
                      bloc: bloc,
                      nameController: _nameController,
                      nationalIdController: _nationalIdController,
                      emailController: _emailController,
                      phoneController: _phoneController,
                      termsRecognizer: _termsRecognizer,
                    ),
            ),
          ),
        );
      },
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.state,
    required this.bloc,
    required this.nameController,
    required this.nationalIdController,
    required this.emailController,
    required this.phoneController,
    required this.termsRecognizer,
  });

  final SignUpClientState state;
  final SignUpClientBloc bloc;
  final TextEditingController nameController;
  final TextEditingController nationalIdController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TapGestureRecognizer termsRecognizer;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.sm),
        Text(
          context.tr('auth.client_signup_title'),
          style: AppTextStyles.h1.copyWith(color: AppColors.ink),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          context.tr('auth.client_signup_subtitle'),
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppTextField(
          label: context.tr('auth.full_name'),
          isRequired: true,
          controller: nameController,
          hint: context.tr('auth.full_name_hint'),
          inputFormatters: [
            FilteringTextInputFormatter.allow(
              RegExp(r'[\u0600-\u06FFa-zA-Z\s]'),
            ),
          ],
          errorText: state.fullNameError != null
              ? context.tr(state.fullNameError!)
              : null,
          textInputAction: TextInputAction.next,
          onChanged: (val) => bloc.add(SignUpClientFullNameChanged(val)),
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: context.tr('auth.national_id'),
          isRequired: true,
          controller: nationalIdController,
          hint: context.tr('auth.national_id_hint'),
          keyboardType: TextInputType.number,
          isMonospace: true,
          errorText: state.nationalIdError != null
              ? context.tr(state.nationalIdError!)
              : null,
          textInputAction: TextInputAction.next,
          onChanged: (val) => bloc.add(SignUpClientNationalIdChanged(val)),
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: context.tr('auth.email'),
          isRequired: true,
          controller: emailController,
          hint: context.tr('auth.email_hint'),
          keyboardType: TextInputType.emailAddress,
          errorText: state.emailError != null
              ? context.tr(state.emailError!)
              : null,
          textInputAction: TextInputAction.next,
          onChanged: (val) => bloc.add(SignUpClientEmailChanged(val)),
        ),
        const SizedBox(height: AppSpacing.md),
        AppPhoneField(
          label: context.tr('auth.phone'),
          isRequired: true,
          controller: phoneController,
          hint: context.tr('auth.phone_hint'),
          errorText: state.phoneError != null
              ? context.tr(state.phoneError!)
              : null,
          textInputAction: TextInputAction.done,
          onChanged: (val) => bloc.add(SignUpClientPhoneChanged(val)),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCheckbox(
          value: state.termsAgreed,
          labelWidget: RichText(
            text: TextSpan(
              style: AppTextStyles.body.copyWith(
                color: AppColors.ink,
                height: 1.4,
              ),
              children: [
                TextSpan(text: context.tr('auth.accept_terms_prefix')),
                TextSpan(
                  text: context.tr('auth.terms_and_privacy'),
                  recognizer: termsRecognizer,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.primary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          onChanged: (val) => bloc.add(SignUpClientTermsToggled(val)),
        ),
        if (state.termsError != null) ...[
          const SizedBox(height: AppSpacing.xxs),
          Text(
            context.tr(state.termsError!),
            style: AppTextStyles.caption.copyWith(color: AppColors.error),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          label: context.tr('auth.create_account'),
          isLoading: state.isSubmitting,
          onPressed: () {
            FocusScope.of(context).unfocus();
            bloc.add(const SignUpClientSubmitted());
          },
        ),
        const SizedBox(height: AppSpacing.md),
        const _ExistingUserHint(),
      ],
    );
  }
}

class _OtpSection extends StatelessWidget {
  const _OtpSection({required this.state, required this.bloc});

  final SignUpClientState state;
  final SignUpClientBloc bloc;

  static String _time(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final rest = (seconds % 60).toString().padLeft(2, '0');
    return '\u202A$minutes:$rest\u202C';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.sm),
        Text(
          context.tr('auth.otp_title'),
          style: AppTextStyles.h1.copyWith(color: AppColors.ink),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          context.tr('auth.otp_subtitle', namedArgs: {'email': state.email}),
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xl),
        Center(
          child: AppOtpInput(
            length: 6,
            enabled: !state.isSubmitting,
            errorText: state.otpError != null
                ? context.tr(state.otpError!)
                : null,
            onChanged: (val) => bloc.add(SignUpClientOtpChanged(val)),
            onCompleted: (_) => bloc.add(const SignUpClientOtpSubmitted()),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          label: context.tr('auth.confirm'),
          isLoading: state.isSubmitting,
          onPressed: () {
            FocusScope.of(context).unfocus();
            bloc.add(const SignUpClientOtpSubmitted());
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        if (!state.canResend)
          Text(
            context.tr(
              'auth.resend_countdown',
              namedArgs: {'time': _time(state.resendSeconds)},
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
                onTap: () => bloc.add(const SignUpClientOtpResendRequested()),
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
      ],
    );
  }
}

/// "Already have an account? Log In".
class _ExistingUserHint extends StatelessWidget {
  const _ExistingUserHint();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          context.tr('auth.already_have_account'),
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(width: AppSpacing.xs),
        GestureDetector(
          onTap: () => context.goNamed(AuthRoutes.loginName),
          child: Text(
            context.tr('auth.login_title'),
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
