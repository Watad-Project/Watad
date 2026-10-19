import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/offer_status.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/work/contractor/datasource/models/contractor_open_project_model.dart';

void main() {
  group('ContractorOpenProjectModel.fromJson', () {
    test('parses a realistic v_open_projects row with an active offer', () {
      final json = <String, dynamic>{
        'id': 'proj-101',
        'title': 'ترميم واجهة فيلا سكنية',
        'description': 'ترميم كامل للواجهة الحجرية مع الدهان الخارجي.',
        'budget': 45000.5,
        'city': 'الرياض',
        'district': 'حي الياسمين',
        'created_at': '2026-10-18T12:30:00.000Z',
        'owner_name': 'خالد الحربي',
        'offer_count': 4,
        'my_offer_id': 'offer-55',
        'my_offer_amount': 42000,
        'my_offer_status': 'pending',
        'is_mine': false,
      };

      final model = ContractorOpenProjectModel.fromJson(json);

      expect(model.id, 'proj-101');
      expect(model.title, 'ترميم واجهة فيلا سكنية');
      expect(
        model.description,
        'ترميم كامل للواجهة الحجرية مع الدهان الخارجي.',
      );
      expect(model.budget, const Money.halalas(4500050));
      expect(model.city, 'الرياض');
      expect(model.district, 'حي الياسمين');
      expect(model.createdAt, DateTime.utc(2026, 10, 18, 12, 30));
      expect(model.ownerName, 'خالد الحربي');
      expect(model.offerCount, 4);
      expect(model.myOfferId, 'offer-55');
      expect(model.myOfferAmount, const Money.halalas(4200000));
      expect(model.myOfferStatus, OfferStatus.pending);
      expect(model.isMine, isFalse);
      expect(model.hasMyOffer, isTrue);
      expect(model.isMyOfferPending, isTrue);
    });

    test('handles nullable fields and missing values gracefully', () {
      final json = <String, dynamic>{
        'id': 'proj-102',
        'title': 'إصلاح تمديدات صحية',
        'description': 'إصلاح تسريب في الخزان الأرضي.',
        'budget': null,
        'city': 'المدينة المنورة',
        'district': null,
        'created_at': null,
        'owner_name': 'سعد العتيبي',
        'offer_count': 0,
        'my_offer_id': null,
        'my_offer_amount': null,
        'my_offer_status': null,
        'is_mine': false,
      };

      final model = ContractorOpenProjectModel.fromJson(json);

      expect(model.id, 'proj-102');
      expect(model.budget, isNull);
      expect(model.district, isNull);
      expect(
        model.createdAt,
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      );
      expect(model.offerCount, 0);
      expect(model.myOfferId, isNull);
      expect(model.myOfferAmount, isNull);
      expect(model.myOfferStatus, isNull);
      expect(model.hasMyOffer, isFalse);
      expect(model.isMyOfferPending, isFalse);
    });
  });
}
