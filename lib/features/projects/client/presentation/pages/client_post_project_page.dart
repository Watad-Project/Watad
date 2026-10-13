import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/layout/app_action_bar.dart';
import 'package:watad/core/components/layout/app_top_bar.dart';
import 'package:watad/core/router/routes/client_navigation_routes.dart';
import 'package:watad/core/theme/app_colors.dart';

import 'package:watad/features/projects/client/presentation/bloc/client_post_project_bloc.dart';
import 'package:watad/features/projects/client/presentation/widgets/client_post_project_step1.dart';

/// The client's main flow for posting a construction project.
class ClientPostProjectPage extends StatelessWidget {
  const ClientPostProjectPage({super.key});

  void _onBack(BuildContext context, ClientPostProjectState state) {
    if (state.currentStep > 1) {
      context.read<ClientPostProjectBloc>().add(
        const ClientPostProjectStepRetreated(),
      );
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(ClientNavigationRoutes.navigationName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClientPostProjectBloc, ClientPostProjectState>(
      builder: (context, state) {
        final canPop = state.currentStep == 1;

        return PopScope(
          canPop: canPop,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && state.currentStep > 1) {
              context.read<ClientPostProjectBloc>().add(
                const ClientPostProjectStepRetreated(),
              );
            }
          },
          child: Scaffold(
            backgroundColor: AppColors.surface,
            appBar: AppTopBar(
              title: context.tr('projects.client.step_1'),
              onBack: () => _onBack(context, state),
            ),
            body: SafeArea(
              child: switch (state.currentStep) {
                1 => ClientPostProjectStep1(
                  selectedType: state.projectType,
                  onTypeChanged: (type) {
                    context.read<ClientPostProjectBloc>().add(
                      ClientPostProjectTypeSelected(type),
                    );
                  },
                ),
                _ => const SizedBox.shrink(),
              },
            ),
            bottomNavigationBar: AppActionBar(
              primary: AppButton(
                label: context.tr('projects.client.next_button'),
                onPressed: state.canProceedFromStep1
                    ? () {
                        context.read<ClientPostProjectBloc>().add(
                          const ClientPostProjectStepAdvanced(),
                        );
                      }
                    : null,
              ),
            ),
          ),
        );
      },
    );
  }
}
