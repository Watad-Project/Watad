import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/feedback/app_empty_view.dart';
import 'package:watad/core/components/feedback/app_error_view.dart';
import 'package:watad/core/components/feedback/app_shimmer.dart';
import 'package:watad/core/components/layout/app_top_bar.dart';
import 'package:watad/core/router/routes/chat_routes.dart';
import 'package:watad/core/theme/app_motion.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/features/chat/shared/presentation/bloc/chats_bloc.dart';
import 'package:watad/features/chat/shared/presentation/widgets/chat_list_tile.dart';

/// «المحادثات» — every chat I'm in, the latest first, with what waits
/// unread. A tap opens the conversation. It's the clients' and contractors'
/// «المحادثات» tab, and a page of its own at /chat.
class ChatsPage extends StatelessWidget {
  const ChatsPage({this.isTab = false, this.bell, super.key});

  /// Shown as a tab: no back arrow.
  final bool isTab;

  /// The notifications bell, lent by that feature (AppSlots.notificationsBell).
  final Widget? bell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(
        title: context.tr('chat.tab'),
        onBack: isTab ? null : () => context.pop(),
        actions: [?bell],
      ),
      body: BlocBuilder<ChatsBloc, ChatsState>(
        builder: (context, state) => AnimatedSwitcher(
          duration: AppMotion.enter,
          reverseDuration: AppMotion.exit,
          switchInCurve: AppMotion.enterCurve,
          switchOutCurve: AppMotion.exitCurve,
          child: _body(context, state),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, ChatsState state) {
    final bloc = context.read<ChatsBloc>();
    if (state.chats.isEmpty) {
      return switch (state.status) {
        ChatsStatus.failure => AppErrorView(
          key: const ValueKey('error'),
          message: context.tr(state.failure!.messageKey),
          onRetry: () => bloc.add(const ChatsFetched()),
        ),
        ChatsStatus.success => RefreshIndicator(
          key: const ValueKey('empty'),
          onRefresh: () async => bloc.add(const ChatsFetched()),
          child: ListView(
            children: [
              AppEmptyView(
                message: context.tr('chat.no_chats'),
                icon: Icons.chat_bubble_outline_rounded,
              ),
            ],
          ),
        ),
        _ => const _ChatsSkeleton(key: ValueKey('loading')),
      };
    }
    final now = DateTime.now();
    return RefreshIndicator(
      key: const ValueKey('chats'),
      onRefresh: () async => bloc.add(const ChatsFetched()),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: state.chats.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final chat = state.chats[index];
          return ChatListTile(
            chat: chat,
            now: now,
            onTap: () async {
              await context.pushNamed(
                ChatRoutes.chatConversationName,
                pathParameters: {'chatId': chat.chatId},
              );
              // Reading it there lowers its unread count here.
              bloc.add(const ChatsFetched());
            },
          );
        },
      ),
    );
  }
}

/// The chats while they load: rows shaped like ChatListTile, shimmering.
class _ChatsSkeleton extends StatelessWidget {
  const _ChatsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Column(
        children: [
          for (var i = 0; i < 5; i++)
            const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  AppSkeletonBox(height: 48, width: 48, radius: AppRadius.pill),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppSkeletonBox(height: 14, width: 140),
                        SizedBox(height: AppSpacing.xs),
                        AppSkeletonBox(height: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
