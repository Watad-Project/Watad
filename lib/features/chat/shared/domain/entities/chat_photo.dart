/// A photo to send: its bytes and its file name from the picker.
class ChatPhoto {
  const ChatPhoto({required this.bytes, required this.name});

  final List<int> bytes;
  final String name;

  /// The types the chat-attachments bucket takes, by file extension.
  static const Map<String, String> mimeTypes = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
  };

  /// The lower-case extension, e.g. `jpg`; empty without one.
  String get extension {
    final dot = name.lastIndexOf('.');
    return dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
  }

  /// Null when the bucket would refuse it (e.g. a GIF).
  String? get mimeType => mimeTypes[extension];
}
