import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/components/feedback/app_empty_view.dart';
import 'package:watad/core/components/feedback/app_error_view.dart';
import 'package:watad/core/components/feedback/app_loading_indicator.dart';
import 'package:watad/core/components/feedback/app_snack_bar.dart';
import 'package:watad/core/components/layout/app_top_bar.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/features/projects/client/domain/entities/client_project.dart';
import 'package:watad/features/projects/client/domain/entities/client_project_offer.dart';
import 'package:watad/features/projects/client/presentation/bloc/client_project_offers_bloc.dart';
import 'package:watad/features/projects/client/presentation/widgets/client_number_formatter.dart';
import 'package:watad/features/projects/client/presentation/widgets/client_offer_card.dart';

/// Screen displaying the incoming offers for a specific client project.
class ClientProjectOffersPage extends StatelessWidget {
  const ClientProjectOffersPage({
    super.key,
    required this.projectId,
    this.onMessageContractor,
  });

  final String projectId;
  final void Function(ClientProjectOffer offer)? onMessageContractor;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ClientProjectOffersBloc, ClientProjectOffersState>(
      listener: (context, state) {
        if (state is ClientProjectOffersLoadSuccess &&
            state.acceptedOfferId != null) {
          context.showSuccessSnackBar(
            context.tr('projects.client.offer_accepted_success'),
          );
        }
      },
      builder: (context, state) {
        final project = state is ClientProjectOffersLoadSuccess
            ? state.project
            : null;

        final topBarTitle = project != null
            ? _formatTopBarTitle(project)
            : context.tr('projects.client.incoming_offers');

        final isArabic = context.locale.languageCode == 'ar';

        return Scaffold(
          backgroundColor: AppColors.surface,
          appBar: AppTopBar(
            title: topBarTitle,
            onBack: () => Navigator.of(context).maybePop(),
          ),
          body: switch (state) {
            ClientProjectOffersInitial() ||
            ClientProjectOffersLoadInProgress() => const AppLoadingIndicator(),
            ClientProjectOffersLoadFailure(:final failure) => AppErrorView(
              message: context.tr(failure.messageKey),
              onRetry: () => context.read<ClientProjectOffersBloc>().add(
                ClientProjectOffersFetched(projectId),
              ),
            ),
            ClientProjectOffersLoadSuccess(
              :final project,
              :final offers,
              :final acceptedOfferId,
            ) =>
              RefreshIndicator(
                onRefresh: () async {
                  context.read<ClientProjectOffersBloc>().add(
                    ClientProjectOffersFetched(projectId),
                  );
                },
                color: AppColors.primary,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr(
                                'projects.client.offers_count_title',
                                namedArgs: {
                                  'count': ClientNumberFormatter.formatCount(
                                    offers.length,
                                    isArabic: isArabic,
                                  ),
                                },
                              ),
                              style: AppTextStyles.h1.copyWith(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              _formatDeclaredBudget(
                                context,
                                project,
                                isArabic: isArabic,
                              ),
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (offers.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: AppEmptyView(
                          icon: Icons.local_offer_outlined,
                          title: context.tr('projects.client.no_offers_title'),
                          message: context.tr('projects.client.no_offers_desc'),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        sliver: SliverList.separated(
                          itemCount: offers.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: AppSpacing.md),
                          itemBuilder: (context, index) {
                            final offer = offers[index];
                            final isAccepted = acceptedOfferId == offer.id;
                            return ClientOfferCard(
                              offer: offer,
                              isAccepted: isAccepted,
                              onAccept: () {
                                context.read<ClientProjectOffersBloc>().add(
                                  ClientProjectOfferAccepted(
                                    offerId: offer.id,
                                    expectedAmount: offer.amount,
                                  ),
                                );
                              },
                              onMessage: () {
                                if (onMessageContractor != null) {
                                  onMessageContractor!(offer);
                                } else {
                                  context.showSnackBar(
                                    context.tr(
                                      'projects.client.messaging_upcoming',
                                    ),
                                  );
                                }
                              },
                            );
                          },
                        ),
                      ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: AppSpacing.xl),
                    ),
                  ],
                ),
              ),
          },
        );
      },
    );
  }

  String _formatTopBarTitle(ClientProject project) {
    if (project.district != null && project.district!.isNotEmpty) {
      return '${project.title} — ${project.district}';
    }
    return '${project.title} — ${project.city}';
  }

  String _formatDeclaredBudget(
    BuildContext context,
    ClientProject project, {
    required bool isArabic,
  }) {
    if (project.budgetMin != null && project.budgetMax != null) {
      return context.tr(
        'projects.client.declared_budget_range',
        namedArgs: {
          'min': ClientNumberFormatter.formatAmount(
            project.budgetMin!,
            isArabic: isArabic,
          ),
          'max': ClientNumberFormatter.formatAmount(
            project.budgetMax!,
            isArabic: isArabic,
          ),
        },
      );
    }
    if (project.budget != null) {
      return context.tr(
        'projects.client.declared_budget_single',
        namedArgs: {
          'amount': ClientNumberFormatter.formatAmount(
            project.budget!,
            isArabic: isArabic,
          ),
        },
      );
    }
    return context.tr('projects.client.budget_unspecified');
  }
}
