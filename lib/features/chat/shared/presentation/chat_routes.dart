import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/router/routes/chat_routes.dart';
import 'package:watad/features/chat/shared/domain/entities/chat_start_request.dart';
import 'package:watad/features/chat/shared/presentation/bloc/chat_conversation_bloc.dart';
import 'package:watad/features/chat/shared/presentation/bloc/chat_start_bloc.dart';
import 'package:watad/features/chat/shared/presentation/bloc/chats_bloc.dart';
import 'package:watad/features/chat/shared/presentation/pages/chat_conversation_page.dart';
import 'package:watad/features/chat/shared/presentation/pages/chat_start_page.dart';
import 'package:watad/features/chat/shared/presentation/pages/chats_page.dart';

final List<RouteBase> chatRoutes = [
  GoRoute(
    name: ChatRoutes.chatsName,
    path: ChatRoutes.chatsPath,
    builder: (context, state) => BlocProvider(
      create: (_) => getIt<ChatsBloc>()..add(const ChatsFetched()),
      child: const ChatsPage(),
    ),
  ),
  GoRoute(
    name: ChatRoutes.chatConversationName,
    path: ChatRoutes.chatConversationPath,
    builder: (context, state) => BlocProvider(
      create: (_) =>
          getIt<ChatConversationBloc>()
            ..add(ChatConversationOpened(state.pathParameters['chatId']!)),
      child: const ChatConversationPage(),
    ),
  ),
  GoRoute(
    name: ChatRoutes.chatStartName,
    path: ChatRoutes.chatStartPath,
    builder: (context, state) => BlocProvider(
      create: (_) => getIt<ChatStartBloc>()
        ..add(
          ChatStartRequested(
            ChatStartRequest(
              otherUserId: state.pathParameters['userId']!,
              projectId: state.uri.queryParameters['project'],
            ),
          ),
        ),
      child: const ChatStartPage(),
    ),
  ),
];
