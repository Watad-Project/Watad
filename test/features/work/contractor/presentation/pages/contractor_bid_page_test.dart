import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/components/buttons/app_button.dart';
import 'package:watad/core/components/display/app_avatar.dart';
import 'package:watad/core/components/inputs/app_text_field.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/enums/offer_status.dart';
import 'package:watad/core/enums/verification_status.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/router/routes/contractor_work_routes.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/chat/shared/presentation/pages/chat_conversation_page.dart';
import 'package:watad/features/work/contractor/domain/entities/contractor_bid_details.dart';
import 'package:watad/features/work/contractor/domain/entities/contractor_open_project.dart';

import '../../../../../helpers/fake_chat_repository.dart';
import '../../../../../helpers/fake_contractor_work_repository.dart';
import '../../../../../helpers/fake_splash_repository.dart';
import '../../../../../helpers/pump_router.dart';

class _RecordingBidRepository extends FakeContractorWorkRepository {
  _RecordingBidRepository({required super.bidDetailsResult});

  Money? submittedAmount;
  String? submittedMessage;
  Money? editedAmount;
  String? editedMessage;
  String? withdrawnOfferId;

  @override
  Future<Result<void>> submitOffer({
    required String projectId,
    required Money amount,
    required String message,
  }) async {
    submittedAmount = amount;
    submittedMessage = message;
    return const Success(null);
  }

  @override
  Future<Result<void>> editOffer({
    required String offerId,
    required Money amount,
    required String message,
  }) async {
    editedAmount = amount;
    editedMessage = message;
    return const Success(null);
  }

  @override
  Future<Result<void>> withdrawOffer(String offerId) async {
    withdrawnOfferId = offerId;
    return const Success(null);
  }
}

void main() {
  final sampleProject = ContractorOpenProject(
    id: 'proj-1',
    title: 'تأسيس فيلا سكنية دورين',
    description: 'بناء عظم بالمواد.',
    budget: const Money.halalas(48000000),
    city: 'الرياض',
    district: 'حي الياسمين',
    createdAt: DateTime.utc(2026, 10, 18),
    ownerName: 'فهد الشمري',
    ownerId: 'u-owner',
    offerCount: 3,
  );

  setUp(() {
    registerFakeSplashBloc(FakeSplashRepository());
  });

  tearDown(getIt.reset);

  testWidgets('«استفسار» opens the chat with the client, about the project', (
    tester,
  ) async {
    final chat = FakeChatRepository();
    registerFakeChat(chat);
    registerFakeContractorWorkTab(
      _RecordingBidRepository(
        bidDetailsResult: Success(
          ContractorBidDetails(
            project: sampleProject,
            verificationStatus: VerificationStatus.verified,
          ),
        ),
      ),
    );
    final router = await pumpAppRouter(tester);
    router.goNamed(
      ContractorWorkRoutes.bidName,
      pathParameters: {'projectId': 'proj-1'},
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('contractor_bid_inquire')));
    await tester.pumpAndSettle();

    expect(chat.started, ['u-owner proj-1']);
    expect(find.byType(ChatConversationPage), findsOneWidget);
    await chat.dispose();
  });

  testWidgets('an unverified business that did not bid cannot ask', (
    tester,
  ) async {
    registerFakeContractorWorkTab(
      _RecordingBidRepository(
        bidDetailsResult: Success(
          ContractorBidDetails(
            project: sampleProject,
            verificationStatus: VerificationStatus.pending,
          ),
        ),
      ),
    );
    final router = await pumpAppRouter(tester);
    router.goNamed(
      ContractorWorkRoutes.bidName,
      pathParameters: {'projectId': 'proj-1'},
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('contractor_bid_inquire')), findsNothing);
  });

  testWidgets('submits a new offer when contractor is verified', (
    tester,
  ) async {
    final repository = _RecordingBidRepository(
      bidDetailsResult: Success(
        ContractorBidDetails(
          project: sampleProject,
          verificationStatus: VerificationStatus.verified,
        ),
      ),
    );
    registerFakeContractorWorkTab(repository);

    final router = await pumpAppRouter(tester);
    router.goNamed(
      ContractorWorkRoutes.bidName,
      pathParameters: {'projectId': 'proj-1'},
    );
    await tester.pumpAndSettle();

    expect(find.text('فرص العمل'), findsOneWidget);
    expect(find.text('تأسيس فيلا سكنية دورين'), findsOneWidget);
    expect(find.text('ملكية موثّقة'), findsOneWidget);
    expect(find.text('الرياض · الميزانية 480000.0 ر.س'), findsOneWidget);
    expect(find.text('العنوان'), findsOneWidget);
    expect(find.text('الرياض · حي الياسمين'), findsOneWidget);
    expect(find.text('المتطلبات'), findsOneWidget);
    expect(find.text('بناء عظم بالمواد.'), findsOneWidget);
    expect(find.byType(AppAvatar), findsOneWidget);
    expect(find.text('العميل: فهد الشمري'), findsOneWidget);
    expect(find.byIcon(Icons.home_work_rounded), findsOneWidget);
    expect(
      find.text('يمكنك تعديل العرض أو سحبه ما دام قيد الانتظار.'),
      findsOneWidget,
    );

    final textFields = find.byType(TextFormField);
    expect(textFields, findsNWidgets(2));

    await tester.enterText(textFields.at(0), '450000');
    await tester.enterText(
      textFields.at(1),
      'المدة المتوقعة ٧ أشهر شاملة الهيكل والتشطيب.',
    );

    await tester.tap(find.widgetWithText(AppButton, 'إرسال العرض'));
    await tester.pumpAndSettle();

    expect(repository.submittedAmount, const Money.halalas(45000000));
    expect(
      repository.submittedMessage,
      'المدة المتوقعة ٧ أشهر شاملة الهيكل والتشطيب.',
    );
  });

  testWidgets(
    'prefills existing pending offer, saves edits, and confirms before withdrawal',
    (tester) async {
      final repository = _RecordingBidRepository(
        bidDetailsResult: Success(
          ContractorBidDetails(
            project: sampleProject,
            verificationStatus: VerificationStatus.verified,
            existingOfferId: 'offer-55',
            existingOfferAmount: const Money.halalas(44000000),
            existingOfferMessage: 'عرض مبدئي للعميل.',
            existingOfferStatus: OfferStatus.pending,
          ),
        ),
      );
      registerFakeContractorWorkTab(repository);

      final router = await pumpAppRouter(tester);
      router.goNamed(
        ContractorWorkRoutes.bidName,
        pathParameters: {'projectId': 'proj-1'},
      );
      await tester.pumpAndSettle();

      // Prefilled values
      expect(find.text('440000.0'), findsOneWidget);
      expect(find.text('عرض مبدئي للعميل.'), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'حفظ التعديلات'), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'سحب العرض'), findsOneWidget);

      // Tap withdraw -> opens AppConfirmDialog
      await tester.tap(find.widgetWithText(AppButton, 'سحب العرض'));
      await tester.pumpAndSettle();

      expect(
        find.text('هل أنت متأكد من سحب عرضك؟ لا يمكن التراجع عن هذا الإجراء.'),
        findsOneWidget,
      );

      // Confirm withdrawal
      await tester.tap(find.widgetWithText(AppButton, 'تأكيد السحب'));
      await tester.pumpAndSettle();

      expect(repository.withdrawnOfferId, 'offer-55');
    },
  );

  testWidgets(
    'disables sending and shows verification banner when unverified',
    (tester) async {
      final repository = _RecordingBidRepository(
        bidDetailsResult: Success(
          ContractorBidDetails(
            project: sampleProject,
            verificationStatus: VerificationStatus.pending,
          ),
        ),
      );
      registerFakeContractorWorkTab(repository);

      final router = await pumpAppRouter(tester);
      router.goNamed(
        ContractorWorkRoutes.bidName,
        pathParameters: {'projectId': 'proj-1'},
      );
      await tester.pumpAndSettle();

      expect(
        find.text('لا يمكنك إرسال عرض قبل توثيق رخصة المنشأة.'),
        findsOneWidget,
      );
      expect(find.widgetWithText(AppButton, 'حالة التوثيق'), findsOneWidget);
      expect(find.byType(AppTextField), findsNWidgets(2));
    },
  );
}
