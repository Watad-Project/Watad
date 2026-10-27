import 'package:get_it/get_it.dart';
import 'package:watad/core/router/routes/chat_routes.dart';
import 'package:watad/core/utils/app_notification_links.dart';
import 'package:watad/features/chat/shared/datasource/remote/chat_remote_data_source.dart';
import 'package:watad/features/chat/shared/datasource/repositories/chat_repository_impl.dart';
import 'package:watad/features/chat/shared/domain/repositories/chat_repository.dart';
import 'package:watad/features/chat/shared/domain/usecases/chat_get_conversation_use_case.dart';
import 'package:watad/features/chat/shared/domain/usecases/chat_get_messages_use_case.dart';
import 'package:watad/features/chat/shared/domain/usecases/chat_mark_read_use_case.dart';
import 'package:watad/features/chat/shared/domain/usecases/chat_send_message_use_case.dart';
import 'package:watad/features/chat/shared/domain/usecases/chat_watch_new_messages_use_case.dart';
import 'package:watad/features/chat/shared/presentation/bloc/chat_conversation_bloc.dart';

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
    ..registerFactory(
      () => ChatConversationBloc(getIt(), getIt(), getIt(), getIt(), getIt()),
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
