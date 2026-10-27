import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/components/feedback/app_empty_view.dart';
import 'package:watad/core/components/feedback/app_error_view.dart';
import 'package:watad/core/components/feedback/app_loading_indicator.dart';
import 'package:watad/core/components/layout/app_top_bar.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/router/routes/chat_routes.dart';
import 'package:watad/features/chat/shared/presentation/bloc/chat_start_bloc.dart';

/// Where every «مراسلة» button goes: it opens the chat with that person
/// (and project), then gives its place to the conversation. When the
/// server says no, it says why.
class ChatStartPage extends StatelessWidget {
  const ChatStartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChatStartBloc, ChatStartState>(
      listener: (context, state) {
        if (state case ChatStartLoadSuccess(:final chatId)) {
          context.pushReplacementNamed(
            ChatRoutes.chatConversationName,
            pathParameters: {'chatId': chatId},
          );
        }
      },
      builder: (context, state) => Scaffold(
        appBar: AppTopBar(
          title: context.tr('chat.title'),
          onBack: () => context.pop(),
        ),
        body: switch (state) {
          // The database refuses a project chat with someone who isn't part
          // of it (42501), or someone whose account is closed (P0002).
          ChatStartLoadFailure(failure: PermissionFailure()) => AppEmptyView(
            message: context.tr('chat.start_refused'),
            icon: Icons.block_rounded,
          ),
          ChatStartLoadFailure(failure: NotFoundFailure()) => AppEmptyView(
            message: context.tr('chat.start_not_found'),
            icon: Icons.person_off_outlined,
          ),
          ChatStartLoadFailure(:final failure, :final request) => AppErrorView(
            message: context.tr(failure.messageKey),
            onRetry: () =>
                context.read<ChatStartBloc>().add(ChatStartRequested(request)),
          ),
          _ => const AppLoadingIndicator(),
        },
      ),
    );
  }
}
