import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/display/app_card.dart';
import 'package:watad/core/components/feedback/app_empty_view.dart';
import 'package:watad/core/components/feedback/app_error_view.dart';
import 'package:watad/core/components/feedback/app_loading_indicator.dart';
import 'package:watad/core/components/feedback/app_snack_bar.dart';
import 'package:watad/core/components/layout/app_top_bar.dart';
import 'package:watad/core/router/routes/client_projects_routes.dart';
import 'package:watad/core/theme/app_colors.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/features/projects/client/domain/entities/client_project.dart';
import 'package:watad/features/projects/client/domain/entities/client_project_offer.dart';
import 'package:watad/features/projects/client/presentation/bloc/client_project_offers_bloc.dart';
import 'package:watad/features/projects/client/presentation/widgets/client_offer_card.dart';

class ClientProjectOffersPage extends StatelessWidget {
  const ClientProjectOffersPage({
    required this.projectId,
    this.onChat,
    super.key,
  });

  final String projectId;
  final void Function(ClientProjectOffer offer)? onChat;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppTopBar(
        title: 'projects.client.offers_title'.tr(),
        onBack: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.goNamed(ClientProjectsRoutes.projectsName);
          }
        },
      ),
      body: BlocConsumer<ClientProjectOffersBloc, ClientProjectOffersState>(
        listener: (context, state) {
          if (state is ClientProjectOfferAcceptSuccess) {
            context.showSuccessSnackBar(
              'projects.client.offer_accepted_success'.tr(),
            );
          } else if (state is ClientProjectOfferAcceptFailure) {
            context.showErrorSnackBar(state.failure.messageKey.tr());
          }
        },
        builder: (context, state) => switch (state) {
          ClientProjectOffersInitial() ||
          ClientProjectOffersLoadInProgress() => const AppLoadingIndicator(),
          ClientProjectOffersLoadFailure(:final failure) => AppErrorView(
            message: failure.messageKey.tr(),
            onRetry: () => context.read<ClientProjectOffersBloc>().add(
              ClientProjectOffersFetched(projectId),
            ),
          ),
          ClientProjectOffersLoadSuccess(
            :final project,
            :final offers,
            :final acceptingOfferId,
          ) =>
            _OffersContent(
              projectId: projectId,
              project: project,
              offers: offers,
              acceptingOfferId: acceptingOfferId,
              onChat: onChat,
            ),
          ClientProjectOfferAcceptSuccess(:final project, :final offers) =>
            _OffersContent(
              projectId: projectId,
              project: project,
              offers: offers,
              acceptingOfferId: null,
              onChat: onChat,
            ),
          ClientProjectOfferAcceptFailure(:final project, :final offers) =>
            _OffersContent(
              projectId: projectId,
              project: project,
              offers: offers,
              acceptingOfferId: null,
              onChat: onChat,
            ),
        },
      ),
    );
  }
}

class _OffersContent extends StatelessWidget {
  const _OffersContent({
    required this.projectId,
    required this.project,
    required this.offers,
    required this.acceptingOfferId,
    required this.onChat,
  });

  final String projectId;
  final ClientProject project;
  final List<ClientProjectOffer> offers;
  final String? acceptingOfferId;
  final void Function(ClientProjectOffer offer)? onChat;

  @override
  Widget build(BuildContext context) {
    final location = project.district != null
        ? '${project.city} - ${project.district}'
        : project.city;

    return RefreshIndicator(
      onRefresh: () async {
        context.read<ClientProjectOffersBloc>().add(
          ClientProjectOffersFetched(projectId),
        );
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(project.title, style: AppTextStyles.h1),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.xxs),
                    Expanded(
                      child: Text(
                        location,
                        style: AppTextStyles.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const Divider(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'projects.client.budget_title'.tr(),
                            style: AppTextStyles.caption,
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            project.budget != null
                                ? 'projects.client.budget_amount'.tr(
                                    namedArgs: {
                                      'amount': (project.budget!.halalas / 100)
                                          .toStringAsFixed(2),
                                    },
                                  )
                                : 'projects.client.budget_unspecified'.tr(),
                            style: AppTextStyles.label.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'projects.client.offers_label'.tr(),
                          style: AppTextStyles.caption,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          'projects.client.offers_count'.tr(
                            namedArgs: {'count': '${offers.length}'},
                          ),
                          style: AppTextStyles.label.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (offers.isEmpty)
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.45,
              child: AppEmptyView(
                title: 'projects.client.no_offers_title'.tr(),
                message: 'projects.client.no_offers_message'.tr(),
              ),
            )
          else ...[
            Text(
              'projects.client.incoming_offers_title'.tr(),
              style: AppTextStyles.h2,
            ),
            const SizedBox(height: AppSpacing.sm),
            ...offers.map(
              (offer) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: ClientOfferCard(
                  offer: offer,
                  isAccepting: acceptingOfferId == offer.id,
                  onAccept: () {
                    context.read<ClientProjectOffersBloc>().add(
                      ClientProjectOfferAccepted(
                        projectId: projectId,
                        offerId: offer.id,
                        expectedAmount: offer.amount,
                      ),
                    );
                  },
                  onChat: () => onChat?.call(offer),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
