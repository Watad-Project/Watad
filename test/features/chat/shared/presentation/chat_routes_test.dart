import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/router/routes/chat_routes.dart';
import 'package:watad/core/router/routes/client_projects_routes.dart';
import 'package:watad/core/supabase/app_session.dart';
import 'package:watad/core/utils/app_notification_links.dart';
import 'package:watad/features/chat/shared/presentation/pages/chat_conversation_page.dart';
import 'package:watad/features/chat/shared/presentation/widgets/chat_header.dart';
import 'package:watad/features/chat/shared/presentation/widgets/chat_message_bubble.dart';

import '../../../../helpers/fake_app_session.dart';
import '../../../../helpers/fake_chat_repository.dart';
import '../../../../helpers/fake_client_projects_repository.dart';
import '../../../../helpers/fake_splash_repository.dart';
import '../../../../helpers/pump_component.dart';
import '../../../../helpers/pump_router.dart';

void main() {
  late FakeChatRepository repository;
  final now = DateTime.now().toUtc();

  setUp(() {
    // The router opens at the splash page first. Its fake never answers.
    registerFakeSplashBloc(FakeSplashRepository());
    repository = FakeChatRepository()
      ..messages = [
        fakeChatMessage(
          'm-2',
          at: now.subtract(const Duration(minutes: 1)),
          content: 'تفضل، هذه صورة الواجهة',
          photoPath: 'c-1/1.jpg',
        ),
        fakeChatMessage(
          'm-1',
          at: now.subtract(const Duration(days: 1)),
          mine: true,
          read: true,
          content: 'السلام عليكم',
        ),
      ];
    registerFakeChat(repository);
  });

  tearDown(() async {
    AppNotificationLinks.clear();
    await repository.dispose();
    await getIt.reset();
  });

  Future<GoRouter> openChat(
    WidgetTester tester, {
    double textScale = 1,
    bool boldText = false,
  }) async {
    final router = await pumpAppRouter(
      tester,
      session: FakeAppSession()..signIn(AppRole.client),
      textScale: textScale,
      boldText: boldText,
    );
    router.goNamed(
      ChatRoutes.chatConversationName,
      pathParameters: {'chatId': fakeChatId},
    );
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('chat-conversation opens the chat at its path', (tester) async {
    final router = await openChat(tester);

    expect(currentPath(router), '/chat/c-1');
    expect(find.byType(ChatConversationPage), findsOneWidget);
    expect(find.text('مؤسسة الأساس الحديث'), findsOneWidget);
    expect(find.byType(ChatHeader), findsOneWidget);
    expect(find.text('المشروع: فيلا سكنية'), findsOneWidget);
    expect(find.byType(ChatMessageBubble), findsNWidgets(2));
    expect(find.text('السلام عليكم'), findsOneWidget);
    // Two days, each under its divider.
    expect(find.text('اليوم'), findsOneWidget);
    expect(find.text('أمس'), findsOneWidget);
    // My message was read: the double tick.
    expect(find.byIcon(Icons.done_all_rounded), findsOneWidget);
    expect(repository.readMarks, 1);
  });

  testWidgets('sending text clears the composer and shows the message', (
    tester,
  ) async {
    await openChat(tester);

    await tester.enterText(find.byType(TextField), 'متى تبدأون؟');
    await tester.pump();
    repository.messages = [
      fakeChatMessage('m-3', at: now, mine: true, content: 'متى تبدأون؟'),
      ...repository.messages,
    ];
    await tester.tap(find.byTooltip('إرسال'));
    await tester.pumpAndSettle();

    expect(repository.sent, ['text: متى تبدأون؟']);
    expect(find.text('متى تبدأون؟'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      isEmpty,
    );
  });

  testWidgets('the project opens my side of it', (tester) async {
    // The project's own screen; what it shows doesn't matter here.
    registerFakeClientProjects(
      FakeClientProjectsRepository()
        ..projectResult = const Failed(NotFoundFailure()),
    );
    final router = await openChat(tester);

    await tester.tap(find.text('المشروع: فيلا سكنية'));
    await tester.pumpAndSettle();
    // Pushed on top of the chat.
    final top = router.routerDelegate.currentConfiguration.last;
    expect(top.route.name, ClientProjectsRoutes.projectTasksName);
    expect(top.matchedLocation, '/client/projects/p-1');
  });

  testWidgets('a chat I am not in says so', (tester) async {
    repository.conversationResult = fakeChatNotFound;
    await openChat(tester);

    expect(find.text('لم نجد هذه المحادثة.'), findsOneWidget);
  });

  testWidgets('an empty chat invites the first message', (tester) async {
    repository.messages = [];
    await openChat(tester);

    expect(find.text('لا توجد رسائل بعد. ابدأ المحادثة.'), findsOneWidget);
  });

  testWidgets('fits large bold text', (tester) async {
    await openChat(tester, textScale: largeTextScale, boldText: true);

    expect(find.byType(ChatConversationPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('a new-message notification opens its chat', () {
    final link = AppNotificationLinks.linkOf({
      'type': 'message',
      'chat_id': 'c-9',
    });
    expect(link?.name, ChatRoutes.chatConversationName);
    expect(link?.pathParameters, {'chatId': 'c-9'});
    expect(AppNotificationLinks.linkOf({'type': 'message'}), isNull);
  });
}
