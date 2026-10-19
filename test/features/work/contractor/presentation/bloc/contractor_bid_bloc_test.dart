import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/offer_status.dart';
import 'package:watad/core/enums/verification_status.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/core/utils/money.dart';
import 'package:watad/features/work/contractor/domain/entities/contractor_bid_details.dart';
import 'package:watad/features/work/contractor/domain/entities/contractor_open_project.dart';
import 'package:watad/features/work/contractor/domain/repositories/contractor_work_repository.dart';
import 'package:watad/features/work/contractor/domain/usecases/contractor_edit_offer_use_case.dart';
import 'package:watad/features/work/contractor/domain/usecases/contractor_get_bid_details_use_case.dart';
import 'package:watad/features/work/contractor/domain/usecases/contractor_submit_offer_use_case.dart';
import 'package:watad/features/work/contractor/domain/usecases/contractor_withdraw_offer_use_case.dart';
import 'package:watad/features/work/contractor/presentation/bloc/contractor_bid_bloc.dart';

import '../../../../../helpers/fake_contractor_work_repository.dart';

ContractorBidBloc _createBloc(ContractorWorkRepository repository) {
  return ContractorBidBloc(
    ContractorGetBidDetailsUseCase(repository),
    ContractorSubmitOfferUseCase(repository),
    ContractorEditOfferUseCase(repository),
    ContractorWithdrawOfferUseCase(repository),
  );
}

void main() {
  final sampleProject = ContractorOpenProject(
    id: 'proj-1',
    title: 'تأسيس عظم دورين',
    description: 'بناء عظم بالمواد.',
    budget: const Money.halalas(48000000),
    city: 'الرياض',
    district: 'حي الياسمين',
    createdAt: DateTime.utc(2026, 10, 18),
    ownerName: 'فيصل العتيبي',
    offerCount: 2,
  );

  group('ContractorBidBloc', () {
    test('parseBidMoney supports Western and Arabic-Indic digits', () {
      expect(
        ContractorBidBloc.parseBidMoney('450000'),
        const Money.halalas(45000000),
      );
      expect(
        ContractorBidBloc.parseBidMoney('٤٥٠٬٠٠٠٫٥٠'),
        const Money.halalas(45000050),
      );
      expect(ContractorBidBloc.parseBidMoney('0'), isNull);
      expect(ContractorBidBloc.parseBidMoney('12.345'), isNull);
      expect(ContractorBidBloc.parseBidMoney('abc'), isNull);
    });

    test('emits LoadInProgress then Ready on ContractorBidStarted', () async {
      final bloc = _createBloc(
        FakeContractorWorkRepository(
          bidDetailsResult: Success(
            ContractorBidDetails(
              project: sampleProject,
              verificationStatus: VerificationStatus.verified,
            ),
          ),
        ),
      );
      addTearDown(bloc.close);

      final states = <ContractorBidState>[];
      final sub = bloc.stream.listen(states.add);
      addTearDown(sub.cancel);

      bloc.add(const ContractorBidStarted('proj-1'));
      await Future<void>.delayed(Duration.zero);

      expect(states, hasLength(2));
      expect(states[0], isA<ContractorBidLoadInProgress>());
      expect(states[1], isA<ContractorBidReady>());
    });

    test(
      'emits LoadInProgress then LoadFailure when getBidDetails fails',
      () async {
        final bloc = _createBloc(
          const FakeContractorWorkRepository(
            bidDetailsResult: Failed(NetworkFailure()),
          ),
        );
        addTearDown(bloc.close);

        final states = <ContractorBidState>[];
        final sub = bloc.stream.listen(states.add);
        addTearDown(sub.cancel);

        bloc.add(const ContractorBidStarted('proj-1'));
        await Future<void>.delayed(Duration.zero);

        expect(states, hasLength(2));
        expect(states[0], isA<ContractorBidLoadInProgress>());
        expect(states[1], isA<ContractorBidLoadFailure>());
      },
    );

    test(
      'sets field error keys when submitting empty amount or message',
      () async {
        final bloc = _createBloc(
          FakeContractorWorkRepository(
            bidDetailsResult: Success(
              ContractorBidDetails(
                project: sampleProject,
                verificationStatus: VerificationStatus.verified,
              ),
            ),
          ),
        );
        addTearDown(bloc.close);

        bloc
          ..add(const ContractorBidStarted('proj-1'))
          ..add(const ContractorBidSubmitted(amountText: '', message: ''));
        await Future<void>.delayed(Duration.zero);

        final ready = bloc.state as ContractorBidReady;
        expect(ready.amountErrorKey, 'work.contractor.bid_amount_required');
        expect(ready.messageErrorKey, 'work.contractor.bid_message_required');
      },
    );

    test('submits new offer and sets completedMessageKey on success', () async {
      final bloc = _createBloc(
        FakeContractorWorkRepository(
          bidDetailsResult: Success(
            ContractorBidDetails(
              project: sampleProject,
              verificationStatus: VerificationStatus.verified,
            ),
          ),
        ),
      );
      addTearDown(bloc.close);

      bloc
        ..add(const ContractorBidStarted('proj-1'))
        ..add(
          const ContractorBidSubmitted(
            amountText: '٤٥٠٠٠٠',
            message: 'التنفيذ خلال ٦ أشهر.',
          ),
        );
      await Future<void>.delayed(Duration.zero);

      final ready = bloc.state as ContractorBidReady;
      expect(ready.completedMessageKey, 'work.contractor.offer_sent_success');
    });

    test('edits and withdraws existing pending offer', () async {
      final bloc = _createBloc(
        FakeContractorWorkRepository(
          bidDetailsResult: Success(
            ContractorBidDetails(
              project: sampleProject,
              verificationStatus: VerificationStatus.verified,
              existingOfferId: 'offer-10',
              existingOfferAmount: const Money.halalas(45000000),
              existingOfferMessage: 'عرض سابق',
              existingOfferStatus: OfferStatus.pending,
            ),
          ),
        ),
      );
      addTearDown(bloc.close);

      bloc
        ..add(const ContractorBidStarted('proj-1'))
        ..add(
          const ContractorBidSubmitted(
            amountText: '430000',
            message: 'عرض معدل',
          ),
        );
      await Future<void>.delayed(Duration.zero);

      final afterEdit = bloc.state as ContractorBidReady;
      expect(
        afterEdit.completedMessageKey,
        'work.contractor.offer_updated_success',
      );

      bloc.add(const ContractorBidWithdrawn());
      await Future<void>.delayed(Duration.zero);

      final afterWithdraw = bloc.state as ContractorBidReady;
      expect(
        afterWithdraw.completedMessageKey,
        'work.contractor.offer_withdrawn_success',
      );
    });
  });
}
