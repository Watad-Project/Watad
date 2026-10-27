import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/display/app_money_text.dart';
import 'package:watad/core/components/feedback/app_confirm_dialog.dart';
import 'package:watad/core/components/feedback/app_empty_view.dart';
import 'package:watad/core/components/feedback/app_error_view.dart';
import 'package:watad/core/components/feedback/app_snack_bar.dart';
import 'package:watad/core/components/layout/app_top_bar.dart';
import 'package:watad/core/localization/app_localization.dart';
import 'package:watad/core/router/routes/chat_routes.dart';
import 'package:watad/core/theme/app_motion.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/core/theme/app_text_styles.dart';
import 'package:watad/features/projects/client/domain/entities/client_project.dart';
import 'package:watad/features/projects/client/domain/entities/client_project_offer.dart';
import 'package:watad/features/projects/client/presentation/bloc/client_project_offers_bloc.dart';
import 'package:watad/features/projects/client/presentation/widgets/client_offer_card.dart';
import 'package:watad/features/projects/client/presentation/widgets/client_project_title.dart';
import 'package:watad/features/projects/client/presentation/widgets/client_projects_skeleton.dart';

/// «العروض الواردة»: the offers on one project, cheapest first.
class ClientProjectOffersPage extends StatelessWidget {
  const ClientProjectOffersPage({required this.projectId, super.key});

  final String projectId;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ClientProjectOffersBloc, ClientProjectOffersState>(
      listenWhen: (previous, current) =>
          current.message != null && previous.message != current.message,
      listener: (context, state) {
        final message = state.message!;
        if (message.isError) {
          context.showErrorSnackBar(context.tr(message.key));
        } else {
          context.showSuccessSnackBar(context.tr(message.key));
        }
      },
      builder: (context, state) {
        final project = state.project;
        return Scaffold(
          appBar: AppTopBar(
            title: project == null ? '' : _place(context, project),
            onBack: () => context.pop(),
          ),
          // Loading, the offers and errors fade into each other.
          body: AnimatedSwitcher(
            duration: AppMotion.enter,
            reverseDuration: AppMotion.exit,
            switchInCurve: AppMotion.enterCurve,
            switchOutCurve: AppMotion.exitCurve,
            child: _body(context, state),
          ),
        );
      },
    );
  }

  /// «فيلا سكنية — حي الياسمين».
  static String _place(BuildContext context, ClientProject project) {
    final title = ClientProjectTitle.of(context, project.title);
    final district = project.district;
    return district == null || district.isEmpty ? title : '$title — $district';
  }

  Widget _body(BuildContext context, ClientProjectOffersState state) {
    final bloc = context.read<ClientProjectOffersBloc>();
    final project = state.project;
    if (project == null) {
      if (state.status == ClientProjectOffersStatus.failure) {
        return AppErrorView(
          key: const ValueKey('error'),
          message: context.tr(state.failure!.messageKey),
          onRetry: () => bloc.add(ClientProjectOffersFetched(projectId)),
        );
      }
      return const ClientProjectsSkeleton(key: ValueKey('loading'));
    }
    final budget = project.budget;
    final count = state.offers.length;
    return RefreshIndicator(
      key: const ValueKey('offers'),
      onRefresh: () async => bloc.add(ClientProjectOffersFetched(projectId)),
      child: ListView(
        padding: const EdgeInsetsDirectional.all(AppSpacing.md),
        children: [
          Text(
            count == 0
                ? context.tr('projects.client.no_offers_yet')
                : context.plural(
                    'projects.client.offers_count',
                    count,
                    args: [context.formatNumber(count)],
                  ),
            style: AppTextStyles.h1,
          ),
          if (budget != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              context.tr(
                'projects.client.declared_budget',
                args: [AppMoneyText.format(context, budget)],
              ),
              style: AppTextStyles.caption,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          if (count == 0)
            AppEmptyView(
              message: context.tr('projects.client.no_offers'),
              icon: Icons.request_quote_outlined,
            )
          else
            for (final offer in state.offers) ...[
              ClientOfferCard(
                offer: offer,
                canAccept: state.canAccept(offer),
                isAccepting: state.acceptingOfferId == offer.id,
                onAccept: state.acceptingOfferId == null
                    ? () => _confirmAccept(context, bloc, offer)
                    : null,
                onMessage: () => context.pushNamed(
                  ChatRoutes.chatStartName,
                  pathParameters: {'userId': offer.providerId},
                  queryParameters: {'project': offer.projectId},
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
        ],
      ),
    );
  }

  Future<void> _confirmAccept(
    BuildContext context,
    ClientProjectOffersBloc bloc,
    ClientProjectOffer offer,
  ) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: context.tr('projects.client.accept_title'),
      message: context.tr(
        'projects.client.accept_message',
        args: [offer.providerName, AppMoneyText.format(context, offer.amount)],
      ),
      confirmLabel: context.tr('projects.client.accept_offer'),
    );
    if (confirmed != null) bloc.add(ClientProjectOfferAccepted(offer));
  }
}
