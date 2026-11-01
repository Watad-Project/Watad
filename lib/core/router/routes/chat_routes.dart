/// The routes of lib/features/chat/shared/. Any feature navigates to them
/// with these names (APP_ARCHITECTURE.md §11).
abstract final class ChatRoutes {
  /// «المحادثات»: every chat I'm in; the clients' and contractors' tab.
  static const String chatsName = 'chats';
  static const String chatsPath = '/chat';

  static const String chatConversationName = 'chat-conversation';
  static const String chatConversationPath = '/chat/:chatId';

  /// Opens the chat with `userId`; with the query parameter `project`, the
  /// chat about that project. Every «مراسلة» button goes here.
  static const String chatStartName = 'chat-start';
  static const String chatStartPath = '/chat/start/:userId';
}
