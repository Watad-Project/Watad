import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/offer_status.dart';
import 'package:watad/core/enums/verification_status.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/work/contractor/datasource/models/contractor_bid_details_model.dart';

void main() {
  group('ContractorBidDetailsModel.fromJson', () {
    test('parses project, verification status, and existing pending offer', () {
      final json = <String, dynamic>{
        'project': {
          'id': 'proj-10',
          'title': 'تأسيس عظم دورين',
          'description': 'بناء عظم بالمواد.',
          'budget': 480000,
          'city': 'الرياض',
          'district': 'حي الملقا',
          'created_at': '2026-10-19T10:00:00.000Z',
          'owner_name': 'تركي الدوسري',
          'offer_count': 3,
          'my_offer_id': 'offer-1',
          'my_offer_amount': 450000,
          'my_offer_status': 'pending',
          'is_mine': false,
        },
        'verification_status': 'verified',
        'offer': {
          'id': 'offer-1',
          'amount': 450000,
          'message': 'التنفيذ خلال ٦ أشهر شاملة الهيكل.',
          'status': 'pending',
          'is_mine': true,
        },
      };

      final model = ContractorBidDetailsModel.fromJson(json);

      expect(model.project, isNotNull);
      expect(model.project!.id, 'proj-10');
      expect(model.project!.budget, const Money.halalas(48000000));
      expect(model.verificationStatus, VerificationStatus.verified);
      expect(model.isVerified, isTrue);
      expect(model.existingOfferId, 'offer-1');
      expect(model.existingOfferAmount, const Money.halalas(45000000));
      expect(model.existingOfferMessage, 'التنفيذ خلال ٦ أشهر شاملة الهيكل.');
      expect(model.existingOfferStatus, OfferStatus.pending);
      expect(model.hasPendingOffer, isTrue);
    });

    test('handles missing project and offer when project is closed', () {
      final json = <String, dynamic>{
        'project': null,
        'verification_status': 'pending',
        'offer': null,
      };

      final model = ContractorBidDetailsModel.fromJson(json);

      expect(model.project, isNull);
      expect(model.verificationStatus, VerificationStatus.pending);
      expect(model.isVerified, isFalse);
      expect(model.existingOfferId, isNull);
      expect(model.hasPendingOffer, isFalse);
    });
  });
}
