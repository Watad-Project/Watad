import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/work/contractor/domain/usecases/contractor_withdraw_offer_use_case.dart';

import '../../../../../helpers/fake_contractor_work_repository.dart';

void main() {
  group('ContractorWithdrawOfferUseCase', () {
    test('returns ValidationFailure when offerId is blank', () async {
      const useCase = ContractorWithdrawOfferUseCase(
        FakeContractorWorkRepository(),
      );

      final result = await useCase('   ');

      expect(result, isA<Failed<void>>());
      expect((result as Failed<void>).failure, isA<ValidationFailure>());
    });

    test('returns Success when offerId is valid', () async {
      const useCase = ContractorWithdrawOfferUseCase(
        FakeContractorWorkRepository(),
      );

      final result = await useCase('offer-99');

      expect(result, isA<Success<void>>());
    });
  });
}
