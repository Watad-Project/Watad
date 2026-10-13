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
import 'package:watad/features/projects/client/presentation/widgets/client_post_project_step2.dart';
import 'package:watad/features/projects/client/presentation/widgets/client_post_project_step3.dart';

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

  String _nextButtonLabel(BuildContext context, ClientPostProjectState state) {
    if (state.currentStep == 1) {
      return context.tr('projects.client.next_button');
    }
    if (state.currentStep == 2) {
      if (state.requiresDeed) {
        return context.tr('projects.client.next_deed_button');
      }
      return context.tr('projects.client.next_review_button');
    }
    return context.tr('projects.client.next_review_button');
  }

  bool _canProceed(ClientPostProjectState state) {
    if (state.currentStep == 1) {
      return state.canProceedFromStep1;
    }
    if (state.currentStep == 2) {
      return state.canProceedFromStep2;
    }
    if (state.currentStep == 3 && state.requiresDeed) {
      return state.canProceedFromStep3;
    }
    return false;
  }

  String _stepTitle(BuildContext context, ClientPostProjectState state) {
    if (state.currentStep == 1) {
      return context.tr('projects.client.step_1');
    }
    return '';
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
              title: _stepTitle(context, state),
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
                2 => ClientPostProjectStep2(
                  state: state,
                  onTypeChanged: (type) {
                    context.read<ClientPostProjectBloc>().add(
                      ClientPostProjectTypeSelected(type),
                    );
                  },
                  onScopeChanged: (scope) {
                    context.read<ClientPostProjectBloc>().add(
                      ClientPostProjectScopeChanged(scope),
                    );
                  },
                  onMinBudgetChanged: (minBudget) {
                    context.read<ClientPostProjectBloc>().add(
                      ClientPostProjectMinBudgetChanged(minBudget),
                    );
                  },
                  onMaxBudgetChanged: (maxBudget) {
                    context.read<ClientPostProjectBloc>().add(
                      ClientPostProjectMaxBudgetChanged(maxBudget),
                    );
                  },
                  onLocationChanged: (location) {
                    context.read<ClientPostProjectBloc>().add(
                      ClientPostProjectLocationChanged(location),
                    );
                  },
                  onPhotoAdded: (photo) {
                    context.read<ClientPostProjectBloc>().add(
                      ClientPostProjectPhotoAdded(photo),
                    );
                  },
                  onPhotoRemoved: (index) {
                    context.read<ClientPostProjectBloc>().add(
                      ClientPostProjectPhotoRemoved(index),
                    );
                  },
                ),
                3 =>
                  state.requiresDeed
                      ? ClientPostProjectStep3(
                          state: state,
                          onUploadDeed: () {
                            context.read<ClientPostProjectBloc>().add(
                              const ClientPostProjectDeedSelected(
                                filePath: 'mock/path/deed.pdf',
                                fileName: 'deed.pdf',
                              ),
                            );
                          },
                          onRetryDeed: () {
                            context.read<ClientPostProjectBloc>().add(
                              const ClientPostProjectDeedRetry(),
                            );
                          },
                        )
                      : const SizedBox.shrink(),
                _ => const SizedBox.shrink(),
              },
            ),
            bottomNavigationBar: AppActionBar(
              primary: AppButton(
                label: _nextButtonLabel(context, state),
                onPressed: _canProceed(state)
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
