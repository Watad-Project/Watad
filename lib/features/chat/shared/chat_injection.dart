import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:watad/core/di/app_slots.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/router/routes/chat_routes.dart';
import 'package:watad/core/usecase/usecase.dart';
import 'package:watad/core/utils/app_notification_links.dart';
import 'package:watad/features/chat/shared/datasource/remote/chat_remote_data_source.dart';
import 'package:watad/features/chat/shared/datasource/repositories/chat_repository_impl.dart';
import 'package:watad/features/chat/shared/domain/repositories/chat_repository.dart';
import 'package:watad/features/chat/shared/domain/usecases/chat_get_conversation_use_case.dart';
import 'package:watad/features/chat/shared/domain/usecases/chat_get_messages_use_case.dart';
import 'package:watad/features/chat/shared/domain/usecases/chat_get_my_chats_use_case.dart';
import 'package:watad/features/chat/shared/domain/usecases/chat_mark_read_use_case.dart';
import 'package:watad/features/chat/shared/domain/usecases/chat_send_message_use_case.dart';
import 'package:watad/features/chat/shared/domain/usecases/chat_start_use_case.dart';
import 'package:watad/features/chat/shared/domain/usecases/chat_watch_my_chats_use_case.dart';
import 'package:watad/features/chat/shared/domain/usecases/chat_watch_new_messages_use_case.dart';
import 'package:watad/features/chat/shared/domain/usecases/chat_watch_unread_total_use_case.dart';
import 'package:watad/features/chat/shared/presentation/bloc/chat_conversation_bloc.dart';
import 'package:watad/features/chat/shared/presentation/bloc/chat_start_bloc.dart';
import 'package:watad/features/chat/shared/presentation/bloc/chats_bloc.dart';
import 'package:watad/features/chat/shared/presentation/widgets/chats_tab.dart';

/// Registers everything in lib/features/chat/shared/.
void registerChatDependencies(GetIt getIt) {
  getIt
    ..registerLazySingleton<ChatRemoteDataSource>(
      () => ChatRemoteDataSourceImpl(getIt()),
    )
    ..registerLazySingleton<ChatRepository>(() => ChatRepositoryImpl(getIt()))
    ..registerLazySingleton(() => ChatGetConversationUseCase(getIt()))
    ..registerLazySingleton(() => ChatGetMessagesUseCase(getIt()))
    ..registerLazySingleton(() => ChatSendMessageUseCase(getIt()))
    ..registerLazySingleton(() => ChatMarkReadUseCase(getIt()))
    ..registerLazySingleton(() => ChatWatchNewMessagesUseCase(getIt()))
    ..registerLazySingleton(() => ChatStartUseCase(getIt()))
    ..registerLazySingleton(() => ChatGetMyChatsUseCase(getIt()))
    ..registerLazySingleton(() => ChatWatchMyChatsUseCase(getIt()))
    ..registerLazySingleton(() => ChatWatchUnreadTotalUseCase(getIt()))
    ..registerFactory(
      () => ChatConversationBloc(getIt(), getIt(), getIt(), getIt(), getIt()),
    )
    ..registerFactory(() => ChatStartBloc(getIt()))
    ..registerFactory(() => ChatsBloc(getIt(), getIt()))
    // The clients' and contractors' navigation shows this as its
    // «المحادثات» tab; the tab reads the chats each time it shows.
    ..registerFactory<Widget>(
      () => ChatsTab(
        bloc: getIt<ChatsBloc>(),
        bell: AppSlots.widget(getIt, AppSlots.notificationsBell),
      ),
      instanceName: ChatRoutes.chatsName,
    )
    // And the tab's badge: the unread total, live. A failed read keeps the
    // last number.
    ..registerFactory<Stream<int>>(
      () =>
          Stream.fromFuture(
            getIt<ChatWatchUnreadTotalUseCase>()(const NoParams()),
          ).asyncExpand(
            (watch) => switch (watch) {
              Success(:final data) => data.expand(
                (count) => [if (count case Success(:final data)) data],
              ),
              Failed() => const Stream<int>.empty(),
            },
          ),
      instanceName: ChatRoutes.chatsName,
    );

  // A new message opens its chat (ARCHITECTURE.md §13).
  AppNotificationLinks.register('message', (data) {
    final chatId = data['chat_id'];
    if (chatId is! String || chatId.isEmpty) return null;
    return (
      name: ChatRoutes.chatConversationName,
      pathParameters: {'chatId': chatId},
    );
  });
}
