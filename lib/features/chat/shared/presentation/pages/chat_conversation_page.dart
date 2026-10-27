import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/feedback/app_empty_view.dart';
import 'package:watad/core/components/feedback/app_error_view.dart';
import 'package:watad/core/components/feedback/app_snack_bar.dart';
import 'package:watad/core/components/layout/app_top_bar.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/router/routes/client_projects_routes.dart';
import 'package:watad/core/router/routes/contractor_tasks_routes.dart';
import 'package:watad/core/theme/app_spacing.dart';
import 'package:watad/features/chat/shared/domain/entities/chat_conversation.dart';
import 'package:watad/features/chat/shared/domain/entities/chat_message.dart';
import 'package:watad/features/chat/shared/domain/entities/chat_project_role.dart';
import 'package:watad/features/chat/shared/presentation/bloc/chat_conversation_bloc.dart';
import 'package:watad/features/chat/shared/presentation/widgets/chat_composer.dart';
import 'package:watad/features/chat/shared/presentation/widgets/chat_day_divider.dart';
import 'package:watad/features/chat/shared/presentation/widgets/chat_header.dart';
import 'package:watad/features/chat/shared/presentation/widgets/chat_message_bubble.dart';
import 'package:watad/features/chat/shared/presentation/widgets/chat_pending_bubble.dart';
import 'package:watad/features/chat/shared/presentation/widgets/chat_skeleton.dart';
import 'package:watad/features/chat/shared/presentation/widgets/chat_time.dart';

/// A conversation: its messages, live, newest at the bottom, and the
/// composer. It covers the whole screen, without the bottom bar.
class ChatConversationPage extends StatefulWidget {
  const ChatConversationPage({super.key});

  /// How often the newest messages are read again while the screen shows,
  /// so my messages' read ticks follow the other side.
  static const Duration refreshEvery = Duration(seconds: 15);

  @override
  State<ChatConversationPage> createState() => _ChatConversationPageState();
}

class _ChatConversationPageState extends State<ChatConversationPage> {
  Timer? _refresh;

  @override
  void initState() {
    super.initState();
    _refresh = Timer.periodic(
      ChatConversationPage.refreshEvery,
      (_) => context.read<ChatConversationBloc>().add(
        const ChatConversationRefreshed(),
      ),
    );
  }

  @override
  void dispose() {
    _refresh?.cancel();
    super.dispose();
  }

  void _openProject(ChatConversation conversation) {
    final projectId = conversation.projectId;
    if (projectId == null) return;
    final name = switch (conversation.projectRole) {
      ChatProjectRole.owner => ClientProjectsRoutes.projectTasksName,
      ChatProjectRole.taker => ContractorTasksRoutes.projectTasksName,
      null => null,
    };
    if (name == null) return;
    context.pushNamed(name, pathParameters: {'projectId': projectId});
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChatConversationBloc, ChatConversationState>(
      listenWhen: (previous, current) =>
          current.notice != null && previous.notice != current.notice,
      listener: (context, state) =>
          context.showErrorSnackBar(context.tr(state.notice!.key)),
      builder: (context, state) {
        final conversation = state.conversation;
        return Scaffold(
          appBar: AppTopBar(
            title:
                conversation?.other?.name ??
                context.tr(
                  conversation == null ? 'chat.title' : 'chat.closed_account',
                ),
            onBack: () => context.pop(),
          ),
          body: switch (state.status) {
            ChatConversationStatus.failure => _Failure(state: state),
            ChatConversationStatus.ready when conversation != null => Column(
              children: [
                ChatHeader(
                  conversation: conversation,
                  now: DateTime.now(),
                  onProjectTap: conversation.projectRole == null
                      ? null
                      : () => _openProject(conversation),
                ),
                Expanded(child: _Messages(state: state)),
                ChatComposer(
                  onSend: (text, photo) => context
                      .read<ChatConversationBloc>()
                      .add(ChatMessageSent(text: text, photo: photo)),
                ),
              ],
            ),
            _ => const ChatSkeleton(),
          },
        );
      },
    );
  }
}

class _Failure extends StatelessWidget {
  const _Failure({required this.state});

  final ChatConversationState state;

  @override
  Widget build(BuildContext context) {
    final failure = state.failure;
    if (failure is NotFoundFailure) {
      return AppEmptyView(
        message: context.tr('chat.not_found'),
        icon: Icons.search_off_rounded,
      );
    }
    return AppErrorView(
      message: context.tr(failure?.messageKey ?? 'errors.unknown'),
      onRetry: () {
        if (state.chatId case final id?) {
          context.read<ChatConversationBloc>().add(ChatConversationOpened(id));
        }
      },
    );
  }
}

/// The messages, newest at the bottom, a divider above each day; scrolling
/// to the top reads older ones.
class _Messages extends StatelessWidget {
  const _Messages({required this.state});

  final ChatConversationState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ChatConversationBloc>();
    if (state.messages.isEmpty && state.pending.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: AppEmptyView(
            message: context.tr('chat.empty_conversation'),
            icon: Icons.chat_bubble_outline_rounded,
          ),
        ),
      );
    }
    final now = DateTime.now();
    // Bottom to top: what I'm sending (today), then the messages newest
    // first. A divider goes above the last message of each day.
    final items = <({ChatPendingMessage? pending, ChatMessage? message})>[
      for (final pending in state.pending.reversed)
        (pending: pending, message: null),
      for (final message in state.messages) (pending: null, message: message),
    ];
    DateTime dayOf(int i) => items[i].message?.createdAt ?? now;
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.extentAfter < 400) {
          bloc.add(const ChatOlderMessagesRequested());
        }
        return false;
      },
      child: ListView.builder(
        reverse: true,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        itemCount: items.length + (state.isLoadingOlder ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == items.length) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final item = items[index];
          final pending = item.pending;
          final message = item.message;
          final bubble = pending != null
              ? ChatPendingBubble(
                  message: pending,
                  onRetry: () => bloc.add(ChatPendingRetried(pending.localId)),
                  onDiscard: () =>
                      bloc.add(ChatPendingDiscarded(pending.localId)),
                )
              : ChatMessageBubble(message: message!);
          final isFirstOfDay =
              index == items.length - 1 ||
              !ChatTime.sameDay(dayOf(index), dayOf(index + 1));
          if (!isFirstOfDay) return bubble;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ChatDayDivider(label: ChatTime.day(context, dayOf(index), now)),
              bubble,
            ],
          );
        },
      ),
    );
  }
}
