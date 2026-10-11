import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/feedback/app_snack_bar.dart';
import 'package:watad/core/components/inputs/app_checkbox.dart';
import 'package:watad/core/components/inputs/app_phone_field.dart';
import 'package:watad/core/components/inputs/app_text_field.dart';
import 'package:watad/core/components/layout/app_step_progress.dart';
import 'package:watad/core/components/layout/app_top_bar.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
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

  @override
  void initState() {
    super.initState();
    _companyNameController = TextEditingController();
    _crNumberController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _crNumberController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
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
          widget.onSuccess?.call(context);
        }
      },
      builder: (context, state) {
        final bloc = context.read<BusinessSignUpBloc>();

        return Scaffold(
          backgroundColor: AppColors.surface,
          appBar: AppTopBar(title: '', onBack: () => context.pop()),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.sm),
                  AppStepProgress(
                    current: 1,
                    total: 2,
                    label: context.tr('auth.business_step_label'),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    context.tr('auth.business_title'),
                    style: AppTextStyles.h1,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    context.tr('auth.business_subtitle'),
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppTextField(
                    label: context.tr('auth.company_name_label'),
                    isRequired: true,
                    controller: _companyNameController,
                    errorText: state.companyNameError?.tr(),
                    onChanged: (val) =>
                        bloc.add(BusinessSignUpCompanyNameChanged(val)),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: context.tr('auth.cr_number_label'),
                    isRequired: true,
                    hint: context.tr('auth.cr_number_hint'),
                    controller: _crNumberController,
                    isMonospace: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    errorText: state.crNumberError?.tr(),
                    onChanged: (val) =>
                        bloc.add(BusinessSignUpCrNumberChanged(val)),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: context.tr('auth.email_label'),
                    isRequired: true,
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    errorText: state.emailError?.tr(),
                    onChanged: (val) =>
                        bloc.add(BusinessSignUpEmailChanged(val)),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppPhoneField(
                    label: context.tr('auth.phone_label'),
                    isRequired: true,
                    controller: _phoneController,
                    errorText: state.phoneError?.tr(),
                    onChanged: (val) =>
                        bloc.add(BusinessSignUpPhoneChanged(val)),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppCheckbox(
                    value: state.termsAgreed,
                    onChanged: (agreed) =>
                        bloc.add(BusinessSignUpTermsToggled(agreed)),
                    label: context.tr('auth.terms_agreement'),
                  ),
                  if (state.termsError != null) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      state.termsError!.tr(),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.error,
                      ),
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
              ),
            ),
          ),
        );
      },
    );
  }
}
