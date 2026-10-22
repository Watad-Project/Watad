import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/verification_status.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/work/contractor/domain/entities/contractor_bid_details.dart';
import 'package:watad/features/work/contractor/domain/usecases/contractor_get_bid_details_use_case.dart';

import '../../../../../helpers/fake_contractor_work_repository.dart';

void main() {
  test(
    'ContractorGetBidDetailsUseCase returns bid details from repository',
    () async {
      const useCase = ContractorGetBidDetailsUseCase(
        FakeContractorWorkRepository(
          bidDetailsResult: Success(
            ContractorBidDetails(
              verificationStatus: VerificationStatus.verified,
              existingOfferId: 'offer-7',
            ),
          ),
        ),
      );

      final result = await useCase('proj-1');

      expect(result, isA<Success<ContractorBidDetails>>());
      expect(
        (result as Success<ContractorBidDetails>).data.existingOfferId,
        'offer-7',
      );
    },
  );
}
