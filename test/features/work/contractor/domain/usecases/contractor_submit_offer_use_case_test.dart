import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/work/contractor/domain/usecases/contractor_submit_offer_use_case.dart';

import '../../../../../helpers/fake_contractor_work_repository.dart';

void main() {
  group('ContractorSubmitOfferUseCase', () {
    test('returns ValidationFailure when amount is zero', () async {
      const useCase = ContractorSubmitOfferUseCase(
        FakeContractorWorkRepository(),
      );

      final result = await useCase(
        const ContractorSubmitOfferParams(
          projectId: 'proj-1',
          amount: Money.zero(),
          message: 'تفاصيل العرض',
        ),
      );

      expect(result, isA<Failed<void>>());
      expect(
        (result as Failed<void>).failure,
        isA<ValidationFailure>().having(
          (f) => f.messageKey,
          'messageKey',
          'work.contractor.bid_amount_invalid',
        ),
      );
    });

    test('returns ValidationFailure when message is blank', () async {
      const useCase = ContractorSubmitOfferUseCase(
        FakeContractorWorkRepository(),
      );

      final result = await useCase(
        const ContractorSubmitOfferParams(
          projectId: 'proj-1',
          amount: Money.halalas(100000),
          message: '   ',
        ),
      );

      expect(result, isA<Failed<void>>());
      expect(
        (result as Failed<void>).failure,
        isA<ValidationFailure>().having(
          (f) => f.messageKey,
          'messageKey',
          'work.contractor.bid_message_required',
        ),
      );
    });

    test('returns Success when amount and message are valid', () async {
      const useCase = ContractorSubmitOfferUseCase(
        FakeContractorWorkRepository(),
      );

      final result = await useCase(
        const ContractorSubmitOfferParams(
          projectId: 'proj-1',
          amount: Money.halalas(2500000),
          message: 'التنفيذ خلال ٥ أشهر.',
        ),
      );

      expect(result, isA<Success<void>>());
    });
  });
}
