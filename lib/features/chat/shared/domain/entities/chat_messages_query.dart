/// Which messages of a chat to read: the newest, those [before] the oldest
/// shown (scrolling up), or those [after] the newest shown (new ones).
class ChatMessagesQuery {
  const ChatMessagesQuery(
    this.chatId, {
    this.before,
    this.after,
    this.limit = pageSize,
  });

  /// How many messages one read brings.
  static const int pageSize = 30;

  final String chatId;
  final DateTime? before;
  final DateTime? after;
  final int limit;
}
