import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/router/routes/chat_routes.dart';
import 'package:watad/features/chat/shared/presentation/bloc/chat_conversation_bloc.dart';
import 'package:watad/features/chat/shared/presentation/pages/chat_conversation_page.dart';

final List<RouteBase> chatRoutes = [
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
];
