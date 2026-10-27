/// The routes of lib/features/chat/shared/. Any feature navigates to them
/// with these names (APP_ARCHITECTURE.md §11).
abstract final class ChatRoutes {
  static const String chatConversationName = 'chat-conversation';
  static const String chatConversationPath = '/chat/:chatId';
}
