import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/display/app_logo.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/features/splash/shared/domain/entities/splash_destination.dart';
import 'package:watad/features/splash/shared/presentation/bloc/splash_bloc.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({this.onNavigate, super.key});

  final void Function(BuildContext context, SplashDestination destination)?
  onNavigate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: BlocConsumer<SplashBloc, SplashState>(
        listener: (context, state) {
          if (state is SplashLoadSuccess) {
            onNavigate?.call(context, state.destination);
          }
        },
        builder: (context, state) {
          if (state is SplashLoadFailure) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      state.failure.messageKey.tr(),
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.neutralLight,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppButton(
                      label: 'common.retry'.tr(),
                      onPressed: () =>
                          context.read<SplashBloc>().add(const SplashStarted()),
                    ),
                  ],
                ),
              ),
            );
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AppLogo(onDark: true, height: 72),
                const SizedBox(height: AppSpacing.md),
                Text(
                  context.tr('splash.tagline'),
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.neutralLight,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
