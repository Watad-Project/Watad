import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/work/contractor/domain/usecases/contractor_edit_offer_use_case.dart';

import '../../../../../helpers/fake_contractor_work_repository.dart';

void main() {
  group('ContractorEditOfferUseCase', () {
    test('returns ValidationFailure when amount is zero or negative', () async {
      const useCase = ContractorEditOfferUseCase(
        FakeContractorWorkRepository(),
      );

      final result = await useCase(
        const ContractorEditOfferParams(
          offerId: 'offer-1',
          amount: Money.zero(),
          message: 'رسالة محدثة',
        ),
      );

      expect(result, isA<Failed<void>>());
      expect((result as Failed<void>).failure, isA<ValidationFailure>());
    });

    test('returns ValidationFailure when message is empty', () async {
      const useCase = ContractorEditOfferUseCase(
        FakeContractorWorkRepository(),
      );

      final result = await useCase(
        const ContractorEditOfferParams(
          offerId: 'offer-1',
          amount: Money.halalas(150000),
          message: '',
        ),
      );

      expect(result, isA<Failed<void>>());
      expect((result as Failed<void>).failure, isA<ValidationFailure>());
    });

    test('returns Success when valid', () async {
      const useCase = ContractorEditOfferUseCase(
        FakeContractorWorkRepository(),
      );

      final result = await useCase(
        const ContractorEditOfferParams(
          offerId: 'offer-1',
          amount: Money.halalas(150000),
          message: 'رسالة محدثة',
        ),
      );

      expect(result, isA<Success<void>>());
    });
  });
}
