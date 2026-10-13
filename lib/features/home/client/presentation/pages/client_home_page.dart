import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/features/home/client/presentation/bloc/client_home_bloc.dart';
import 'package:watad/features/home/client/presentation/widgets/client_home_greeting_header.dart';
import 'package:watad/features/home/client/presentation/widgets/client_post_project_banner.dart';
import 'package:watad/features/home/client/presentation/widgets/client_search_bar.dart';
import 'package:watad/features/home/client/presentation/widgets/client_suggested_contractors_section.dart';

class ClientHomePage extends StatelessWidget {
  const ClientHomePage({this.onStartPostProject, this.currentHour, super.key});

  final VoidCallback? onStartPostProject;
  final int? currentHour;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: BlocBuilder<ClientHomeBloc, ClientHomeState>(
          builder: (context, state) => switch (state) {
            ClientHomeInitial() || ClientHomeLoadInProgress() => const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ),
            ClientHomeLoadFailure(:final failure) => Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      context.tr(failure.messageKey),
                      style: AppTextStyles.body,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppButton(
                      label: context.tr('common.retry'),
                      variant: AppButtonVariant.secondary,
                      onPressed: () => context.read<ClientHomeBloc>().add(
                        const ClientHomeStarted(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ClientHomeLoadSuccess(:final profile, :final contractors) =>
              RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  context.read<ClientHomeBloc>().add(
                    const ClientHomeRefreshed(),
                  );
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ClientHomeGreetingHeader(
                        profile: profile,
                        currentHour: currentHour,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const ClientSearchBar(),
                      const SizedBox(height: AppSpacing.md),
                      ClientPostProjectBanner(
                        onStartPressed: onStartPostProject ?? () {},
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      ClientSuggestedContractorsSection(
                        contractors: contractors,
                      ),
                    ],
                  ),
                ),
              ),
          },
        ),
      ),
    );
  }
}
