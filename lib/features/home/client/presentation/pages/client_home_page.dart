import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/features/home/client/presentation/bloc/client_home_bloc.dart';
import 'package:watad/features/home/client/presentation/widgets/client_home_greeting_header.dart';
import 'package:watad/features/home/client/presentation/widgets/client_post_project_banner.dart';
import 'package:watad/features/home/client/presentation/widgets/client_search_bar.dart';
import 'package:watad/features/home/client/presentation/widgets/client_suggested_contractors_section.dart';

class ClientHomePage extends StatelessWidget {
  const ClientHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: BlocBuilder<ClientHomeBloc, ClientHomeState>(
          builder: (context, state) {
            return switch (state.status) {
              ClientHomeStatus.initial ||
              ClientHomeStatus.loading => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              ClientHomeStatus.failure => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        state.errorMessageKey?.tr() ?? 'home.load_failed'.tr(),
                        style: AppTextStyles.body,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ElevatedButton(
                        onPressed: () {
                          context.read<ClientHomeBloc>().add(
                            const ClientHomeStarted(),
                          );
                        },
                        child: Text('common.retry'.tr()),
                      ),
                    ],
                  ),
                ),
              ),
              ClientHomeStatus.success => RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  context.read<ClientHomeBloc>().add(
                    const ClientHomeRefreshed(),
                  );
                },
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  children: [
                    ClientHomeGreetingHeader(profile: state.profile),
                    const SizedBox(height: AppSpacing.lg),
                    const ClientSearchBar(),
                    const SizedBox(height: AppSpacing.lg),
                    const ClientPostProjectBanner(),
                    const SizedBox(height: AppSpacing.xl),
                    ClientSuggestedContractorsSection(
                      contractors: state.suggestedContractors,
                    ),
                  ],
                ),
              ),
            };
          },
        ),
      ),
    );
  }
}
