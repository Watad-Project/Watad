import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/feedback/app_snack_bar.dart';
import 'package:watad/core/components/layout/app_action_bar.dart';
import 'package:watad/core/components/layout/app_top_bar.dart';
import 'package:watad/core/router/routes/client_navigation_routes.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/features/projects/client/presentation/bloc/client_post_project_bloc.dart';
import 'package:watad/features/projects/client/presentation/widgets/client_post_project_step1.dart';
import 'package:watad/features/projects/client/presentation/widgets/client_post_project_step2.dart';
import 'package:watad/features/projects/client/presentation/widgets/client_post_project_step3.dart';
import 'package:watad/features/projects/client/presentation/widgets/client_post_project_step_review.dart';

/// The client's main flow for posting a construction project.
class ClientPostProjectPage extends StatelessWidget {
  const ClientPostProjectPage({super.key});

  void _safeNavigateHome(BuildContext context) {
    try {
      if (context.canPop()) {
        context.pop();
      } else {
        context.goNamed(ClientNavigationRoutes.navigationName);
      }
    } catch (_) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  void _onBack(BuildContext context, ClientPostProjectState state) {
    if (state.currentStep > 1) {
      context.read<ClientPostProjectBloc>().add(
        const ClientPostProjectStepRetreated(),
      );
    } else {
      _safeNavigateHome(context);
    }
  }

  String _nextButtonLabel(BuildContext context, ClientPostProjectState state) {
    if (state.isReviewStep) {
      return context.tr('projects.client.publish_project_button');
    }
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
    if (state.isReviewStep) {
      return state.canPublish;
    }
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
    return BlocConsumer<ClientPostProjectBloc, ClientPostProjectState>(
      listener: (context, state) {
        if (state.status == ClientPostProjectStatus.success) {
          context.showSuccessSnackBar(
            context.tr('projects.client.publish_success_message'),
          );
          _safeNavigateHome(context);
        }
      },
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
            body: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => FocusScope.of(context).unfocus(),
              child: SafeArea(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  switchInCurve: Curves.easeInOut,
                  switchOutCurve: Curves.easeInOut,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: KeyedSubtree(
                    key: ValueKey<int>(state.currentStep),
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
                            : ClientPostProjectStepReview(state: state),
                      4 => ClientPostProjectStepReview(state: state),
                      _ => const SizedBox.shrink(),
                    },
                  ),
                ),
              ),
            ),
            bottomNavigationBar: AppActionBar(
              primary: AppButton(
                label: _nextButtonLabel(context, state),
                isLoading: state.status == ClientPostProjectStatus.submitting,
                onPressed: _canProceed(state)
                    ? () {
                        if (state.isReviewStep) {
                          context.read<ClientPostProjectBloc>().add(
                            const ClientPostProjectSubmitted(),
                          );
                        } else {
                          context.read<ClientPostProjectBloc>().add(
                            const ClientPostProjectStepAdvanced(),
                          );
                        }
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
