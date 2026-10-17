import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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
    return BlocConsumer<ClientProjectOffersBloc, ClientProjectOffersState>(
      listener: (context, state) {
        if (state is ClientProjectOfferAcceptSuccess) {
          context.showSuccessSnackBar(
            'projects.client.offer_accepted_success'.tr(),
          );
        } else if (state is ClientProjectOfferAcceptFailure) {
          context.showErrorSnackBar(state.failure.messageKey.tr());
        }
      },
      builder: (context, state) {
        final title = switch (state) {
          ClientProjectOffersLoadSuccess(:final project) ||
          ClientProjectOfferAcceptSuccess(:final project) ||
          ClientProjectOfferAcceptFailure(:final project) =>
            project.district != null
                ? '${project.title} — ${project.district}'
                : project.title,
          _ => 'projects.client.offers_title'.tr(),
        };

        return Scaffold(
          backgroundColor: AppColors.surface,
          appBar: AppTopBar(
            title: title,
            onBack: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.goNamed(ClientProjectsRoutes.projectsName);
              }
            },
          ),
          body: switch (state) {
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
        );
      },
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

  static String _toArabicDigits(String input) {
    final codeUnits = input.codeUnits.map((cp) {
      if (cp >= 0x30 && cp <= 0x39) {
        return cp - 0x30 + 0x0660;
      }
      return cp;
    }).toList();
    return String.fromCharCodes(codeUnits);
  }

  String _formatNumber(int value, {bool isArabic = false}) {
    final s = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(s[i]);
    }
    var res = buffer.toString();
    if (isArabic) {
      res = _toArabicDigits(res);
    }
    return res;
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';
    final countStr = isArabic
        ? _toArabicDigits('${offers.length}')
        : '${offers.length}';
    final budgetStr = project.budget != null
        ? _formatNumber(project.budget!.halalas ~/ 100, isArabic: isArabic)
        : null;

    return RefreshIndicator(
      onRefresh: () async {
        context.read<ClientProjectOffersBloc>().add(
          ClientProjectOffersFetched(projectId),
        );
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        children: [
          const SizedBox(height: AppSpacing.xs),
          Text(
            'projects.client.offers_count'.tr(namedArgs: {'count': countStr}),
            style: AppTextStyles.h1.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          if (budgetStr != null)
            Text(
              'projects.client.declared_budget'.tr(
                namedArgs: {'amount': budgetStr},
              ),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
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
          else
            ...offers.map(
              (offer) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
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
      ),
    );
  }
}
