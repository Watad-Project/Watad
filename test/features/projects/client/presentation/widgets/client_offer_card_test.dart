import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/offer_status.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/projects/client/domain/entities/client_project_offer.dart';
import 'package:watad/features/projects/client/presentation/widgets/client_offer_card.dart';

import '../../../../../helpers/pump_component.dart';

void main() {
  final sampleOffer = ClientProjectOffer(
    id: 'offer-1',
    projectId: 'proj-1',
    contractorName: 'Al-Bina Contracting',
    contractorRating: 4.8,
    isContractorVerified: true,
    amount: const Money.halalas(46500000),
    durationMonths: 7,
    status: OfferStatus.pending,
    createdAt: DateTime.utc(2026, 10, 14),
    message: 'Includes exterior finishing',
  );

  testWidgets('shows contractor name, rating, price, duration and message', (
    tester,
  ) async {
    var acceptCount = 0;
    var messageCount = 0;

    await pumpComponent(
      tester,
      ClientOfferCard(
        offer: sampleOffer,
        onAccept: () => acceptCount++,
        onMessage: () => messageCount++,
      ),
    );

    expect(find.text('Al-Bina Contracting'), findsOneWidget);
    expect(find.text('\u0664\u066B\u0668'), findsOneWidget);
    expect(
      find.text('\u0664\u0666\u0665\u066C\u0660\u0660\u0660 \u0631.\u0633'),
      findsOneWidget,
    );
    expect(find.text('\u0667 \u0623\u0634\u0647\u0631'), findsOneWidget);
    expect(find.text('Includes exterior finishing'), findsOneWidget);
    expect(find.text('قبول العرض'), findsOneWidget);
    expect(find.text('مراسلة'), findsOneWidget);

    await tester.tap(find.text('قبول العرض'));
    expect(acceptCount, 1);

    await tester.tap(find.text('مراسلة'));
    expect(messageCount, 1);
  });

  testWidgets('shows offer accepted badge when isAccepted is true', (
    tester,
  ) async {
    await pumpComponent(
      tester,
      ClientOfferCard(offer: sampleOffer, isAccepted: true),
    );

    expect(find.text('تم قبول العرض'), findsOneWidget);
    expect(find.text('قبول العرض'), findsNothing);
  });
}
