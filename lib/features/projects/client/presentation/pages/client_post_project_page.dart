import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
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
import 'package:watad/features/projects/client/presentation/widgets/client_post_project_step2.dart';
import 'package:watad/features/projects/client/presentation/widgets/client_post_project_step3.dart';
import 'package:watad/features/projects/client/presentation/widgets/client_post_project_step_review.dart';

/// The client's main flow for posting a construction project.
class ClientPostProjectPage extends StatelessWidget {
  const ClientPostProjectPage({super.key, this.onPickDeed, this.onPickPhoto});

  /// Injected callback for selecting a deed (e.g. for widget testing).
  final Future<void> Function(BuildContext context)? onPickDeed;

  /// Injected callback for selecting a photo (e.g. for widget testing).
  final Future<void> Function(BuildContext context)? onPickPhoto;

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

  Future<void> _defaultPickDeed(BuildContext context) async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (file == null) {
        return;
      }

      if (context.mounted) {
        context.read<ClientPostProjectBloc>().add(
          ClientPostProjectDeedSelected(
            filePath: file.path ?? file.name,
            fileName: file.name,
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        context.showErrorSnackBar(context.tr('errors.unknown'));
      }
    }
  }

  /// «التالي» on every step, and publishing on the review.
  String _nextButtonLabel(BuildContext context, ClientPostProjectState state) {
    return state.isReviewStep
        ? context.tr('projects.client.publish_project_button')
        : context.tr('projects.client.next_button');
  }

  bool _canProceed(ClientPostProjectState state) {
    if (state.isReviewStep) return state.canPublish;
    return switch (state.currentStep) {
      1 => state.canProceedFromDetails,
      _ => state.canProceedFromDeed,
    };
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ClientPostProjectBloc, ClientPostProjectState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == ClientPostProjectStatus.success) {
          context.showSuccessSnackBar(
            context.tr('projects.client.publish_success_message'),
          );
          _safeNavigateHome(context);
        }
        if (state.status == ClientPostProjectStatus.failure) {
          final messageKey = state.failure?.messageKey;
          if (messageKey != null) {
            context.showErrorSnackBar(context.tr(messageKey));
          }
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
            appBar: AppTopBar(title: '', onBack: () => _onBack(context, state)),
            // The keyboard closes app-wide (AppKeyboardDismiss).
            body: SafeArea(
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
                    // Details first: the type is chosen there.
                    1 => ClientPostProjectStep2(
                      state: state,
                      onPickPhoto: onPickPhoto,
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
                    2 =>
                      state.requiresDeed
                          ? ClientPostProjectStep3(
                              state: state,
                              onUploadDeed: () =>
                                  (onPickDeed ?? _defaultPickDeed)(context),
                              onRetryDeed: () {
                                context.read<ClientPostProjectBloc>().add(
                                  const ClientPostProjectDeedRetry(),
                                );
                                (onPickDeed ?? _defaultPickDeed)(context);
                              },
                            )
                          : ClientPostProjectStepReview(state: state),
                    3 => ClientPostProjectStepReview(state: state),
                    _ => const SizedBox.shrink(),
                  },
                ),
              ),
            ),
            bottomNavigationBar: AppActionBar(
              primary: AppButton(
                key: const Key('client_post_project_next_button'),
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
