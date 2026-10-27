import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/chat/shared/domain/entities/chat_outgoing.dart';
import 'package:watad/features/chat/shared/domain/entities/chat_photo.dart';
import 'package:watad/features/chat/shared/domain/usecases/chat_send_message_use_case.dart';

import '../../../../../helpers/fake_chat_repository.dart';

void main() {
  late FakeChatRepository repository;
  late ChatSendMessageUseCase send;

  setUp(() {
    repository = FakeChatRepository();
    send = ChatSendMessageUseCase(repository);
  });

  test('sends trimmed text', () async {
    expect(
      await send(const ChatOutgoing(chatId: fakeChatId, text: '  مرحبا  ')),
      isA<Success<void>>(),
    );
    expect(repository.sent, ['text: مرحبا']);
  });

  test('sends a photo, with its caption or without', () async {
    const photo = ChatPhoto(bytes: [1, 2, 3], name: 'IMG_1.JPG');
    await send(const ChatOutgoing(chatId: fakeChatId, photo: photo));
    await send(
      const ChatOutgoing(chatId: fakeChatId, text: 'الواجهة', photo: photo),
    );
    expect(repository.sent, ['photo: IMG_1.JPG', 'photo: IMG_1.JPG (الواجهة)']);
  });

  test('refuses nothing to send, a long text and a GIF', () async {
    Future<String?> keyOf(ChatOutgoing message) async =>
        switch (await send(message)) {
          Failed(:final failure) => (failure as ValidationFailure).messageKey,
          Success() => null,
        };

    expect(
      await keyOf(const ChatOutgoing(chatId: fakeChatId, text: '   ')),
      'chat.empty',
    );
    expect(
      await keyOf(ChatOutgoing(chatId: fakeChatId, text: 'ا' * 4001)),
      'chat.too_long',
    );
    expect(
      await keyOf(
        const ChatOutgoing(
          chatId: fakeChatId,
          photo: ChatPhoto(bytes: [1], name: 'a.gif'),
        ),
      ),
      'chat.photo_type',
    );
    expect(repository.sent, isEmpty);
  });
}
