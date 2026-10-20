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
import 'package:watad/core/components/layout/app_step_progress.dart';
import 'package:watad/core/components/layout/app_top_bar.dart';
import 'package:watad/core/router/routes/auth_routes.dart';
import 'package:watad/core/router/routes/contractor_kyc_routes.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/features/auth/shared/domain/usecases/verify_otp_use_case.dart';
import 'package:watad/features/auth/shared/presentation/bloc/business_sign_up_bloc.dart';

class SignUpBusinessPage extends StatefulWidget {
  const SignUpBusinessPage({super.key, this.onSuccess});

  final void Function(BuildContext context)? onSuccess;

  @override
  State<SignUpBusinessPage> createState() => _SignUpBusinessPageState();
}

class _SignUpBusinessPageState extends State<SignUpBusinessPage> {
  late final TextEditingController _companyNameController;
  late final TextEditingController _crNumberController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TapGestureRecognizer _termsLinkRecognizer;

  @override
  void initState() {
    super.initState();
    _companyNameController = TextEditingController();
    _crNumberController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _termsLinkRecognizer = TapGestureRecognizer()..onTap = () {};
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _crNumberController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _termsLinkRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BusinessSignUpBloc, BusinessSignUpState>(
      listener: (context, state) {
        if (state.generalError != null) {
          context.showErrorSnackBar(state.generalError!.tr());
        }
        if (state.status == BusinessSignUpStatus.success) {
          if (widget.onSuccess != null) {
            widget.onSuccess!(context);
          } else {
            context.goNamed(ContractorKycRoutes.licenseName);
          }
        }
      },
      builder: (context, state) {
        final bloc = context.read<BusinessSignUpBloc>();
        final isOtp = state.isOtpStep;

        return Scaffold(
          backgroundColor: AppColors.surface,
          appBar: AppTopBar(
            title: '',
            onBack: () {
              if (isOtp) {
                bloc.add(const BusinessSignUpStepBack());
              } else if (context.canPop()) {
                context.pop();
              } else {
                context.goNamed(AuthRoutes.roleName);
              }
            },
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: isOtp
                  ? _OtpSection(state: state, bloc: bloc)
                  : _FormSection(
                      state: state,
                      bloc: bloc,
                      companyNameController: _companyNameController,
                      crNumberController: _crNumberController,
                      emailController: _emailController,
                      phoneController: _phoneController,
                      termsLinkRecognizer: _termsLinkRecognizer,
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
    required this.companyNameController,
    required this.crNumberController,
    required this.emailController,
    required this.phoneController,
    required this.termsLinkRecognizer,
  });

  final BusinessSignUpState state;
  final BusinessSignUpBloc bloc;
  final TextEditingController companyNameController;
  final TextEditingController crNumberController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TapGestureRecognizer termsLinkRecognizer;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.sm),
        AppStepProgress(
          current: 1,
          total: 2,
          label: context.tr('auth.business_step_label'),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(context.tr('auth.business_title'), style: AppTextStyles.h1),
        const SizedBox(height: AppSpacing.xs),
        Text(
          context.tr('auth.business_subtitle'),
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppTextField(
          label: context.tr('auth.company_name_label'),
          isRequired: true,
          controller: companyNameController,
          errorText: state.companyNameError?.tr(),
          onChanged: (val) => bloc.add(BusinessSignUpCompanyNameChanged(val)),
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: context.tr('auth.cr_number_label'),
          isRequired: true,
          hint: context.tr('auth.cr_number_hint'),
          controller: crNumberController,
          isMonospace: true,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          errorText: state.crNumberError?.tr(),
          onChanged: (val) => bloc.add(BusinessSignUpCrNumberChanged(val)),
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: context.tr('auth.email_label'),
          isRequired: true,
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          errorText: state.emailError?.tr(),
          onChanged: (val) => bloc.add(BusinessSignUpEmailChanged(val)),
        ),
        const SizedBox(height: AppSpacing.md),
        AppPhoneField(
          label: context.tr('auth.phone_label'),
          isRequired: true,
          controller: phoneController,
          errorText: state.phoneError?.tr(),
          onChanged: (val) => bloc.add(BusinessSignUpPhoneChanged(val)),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCheckbox(
          value: state.termsAgreed,
          onChanged: (agreed) => bloc.add(BusinessSignUpTermsToggled(agreed)),
          labelWidget: RichText(
            text: TextSpan(
              style: AppTextStyles.body.copyWith(
                color: AppColors.ink,
                height: 1.4,
              ),
              children: [
                TextSpan(text: context.tr('auth.terms_agreement_prefix')),
                TextSpan(
                  text: context.tr('auth.terms_agreement_link'),
                  style: const TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: termsLinkRecognizer,
                ),
              ],
            ),
          ),
        ),
        if (state.termsError != null) ...[
          const SizedBox(height: AppSpacing.xxs),
          Text(
            state.termsError!.tr(),
            style: AppTextStyles.caption.copyWith(color: AppColors.error),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          label: context.tr('auth.next_upload_license'),
          isLoading: state.isSubmitting,
          onPressed: () {
            FocusScope.of(context).unfocus();
            bloc.add(const BusinessSignUpSubmitted());
          },
        ),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}

class _OtpSection extends StatelessWidget {
  const _OtpSection({required this.state, required this.bloc});

  final BusinessSignUpState state;
  final BusinessSignUpBloc bloc;

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
        AppStepProgress(
          current: 1,
          total: 2,
          label: context.tr('auth.business_step_label'),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(context.tr('auth.otp_title'), style: AppTextStyles.h1),
        const SizedBox(height: AppSpacing.xs),
        Text(
          context.tr('auth.otp_subtitle', namedArgs: {'email': state.email}),
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xl),
        Center(
          child: AppOtpInput(
            length: VerifyOtpUseCase.codeLength,
            enabled: !state.isSubmitting,
            errorText: state.otpError == null
                ? null
                : context.tr(state.otpError!),
            onChanged: (val) => bloc.add(BusinessSignUpOtpChanged(val)),
            onCompleted: (_) => bloc.add(const BusinessSignUpOtpSubmitted()),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          label: context.tr('auth.confirm'),
          isLoading: state.isSubmitting,
          onPressed: () {
            FocusScope.of(context).unfocus();
            bloc.add(const BusinessSignUpOtpSubmitted());
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
                onTap: () => bloc.add(const BusinessSignUpOtpResendRequested()),
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
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}
