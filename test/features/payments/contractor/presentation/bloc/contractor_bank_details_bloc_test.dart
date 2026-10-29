import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/payments/contractor/domain/entities/contractor_bank_details.dart';
import 'package:watad/features/payments/contractor/domain/entities/contractor_bank_details_draft.dart';
import 'package:watad/features/payments/contractor/domain/usecases/contractor_check_bank_details_use_case.dart';
import 'package:watad/features/payments/contractor/domain/usecases/contractor_get_bank_details_use_case.dart';
import 'package:watad/features/payments/contractor/domain/usecases/contractor_save_bank_details_use_case.dart';
import 'package:watad/features/payments/contractor/presentation/bloc/contractor_bank_details_bloc.dart';

import '../../../../../helpers/fake_contractor_payments_repository.dart';

void main() {
  const saved = ContractorBankDetails(
    beneficiaryName: 'مؤسسة البناء المتين',
    bankName: 'مصرف الراجحي',
    iban: 'SA0380000000608010167519',
  );
  // The saved details as people type them: spaces, lower case.
  const typed = ContractorBankDetailsDraft(
    beneficiaryName: ' مؤسسة البناء المتين ',
    bankName: 'مصرف الراجحي',
    iban: 'sa03 8000 0000 6080 1016 7519',
  );
  const otherBank = ContractorBankDetailsDraft(
    beneficiaryName: 'مؤسسة البناء المتين',
    bankName: 'البنك الأهلي السعودي',
    iban: 'SA0380000000608010167519',
  );

  late FakeContractorPaymentsRepository repository;

  setUp(() => repository = FakeContractorPaymentsRepository());

  ContractorBankDetailsBloc buildBloc() => ContractorBankDetailsBloc(
    ContractorGetBankDetailsUseCase(repository),
    const ContractorCheckBankDetailsUseCase(),
    ContractorSaveBankDetailsUseCase(repository),
  );

  Future<ContractorBankDetailsBloc> loadedBloc() async {
    final bloc = buildBloc()..add(const ContractorBankDetailsFetched());
    await bloc.stream.firstWhere(
      (s) => s.status == ContractorBankDetailsStatus.success,
    );
    return bloc;
  }

  /// Adds [event] and waits for the first state that passes [test].
  Future<ContractorBankDetailsState> after(
    ContractorBankDetailsBloc bloc,
    ContractorBankDetailsEvent event,
    bool Function(ContractorBankDetailsState state) test,
  ) {
    final state = bloc.stream.firstWhere(test);
    bloc.add(event);
    return state;
  }

  test('first use: the empty form, with nothing to save', () async {
    final bloc = await loadedBloc();

    expect(bloc.state.saved, isNull);
    expect(bloc.state.showsForm, isTrue);
    expect(bloc.state.canSave, isFalse);
    await bloc.close();
  });

  test('saved details open in view mode', () async {
    repository.saved = saved;
    final bloc = await loadedBloc();

    expect(bloc.state.saved, same(saved));
    expect(bloc.state.showsForm, isFalse);
    await bloc.close();
  });

  test('a failed load says why', () async {
    repository.readResult = const Failed(NetworkFailure());
    final bloc = buildBloc()..add(const ContractorBankDetailsFetched());

    final state = await bloc.stream.firstWhere(
      (s) => s.status == ContractorBankDetailsStatus.failure,
    );

    expect(state.failure, isA<NetworkFailure>());
    await bloc.close();
  });

  test('every change is checked; an empty field shows no error', () async {
    final bloc = await loadedBloc();

    var state = await after(
      bloc,
      const ContractorBankDetailsChanged(
        ContractorBankDetailsDraft(
          beneficiaryName: 'أ',
          bankName: '',
          iban: 'SA0480000000608010167519',
        ),
      ),
      (s) => s.check != null,
    );
    expect(state.beneficiaryNameError, 'validation.beneficiary_name_invalid');
    expect(state.bankNameError, isNull);
    expect(state.ibanError, 'validation.iban_checksum');
    expect(state.canSave, isFalse);

    state = await after(
      bloc,
      const ContractorBankDetailsChanged(typed),
      (s) => s.check?.isValid ?? false,
    );
    expect(state.canSave, isTrue);
    await bloc.close();
  });

  test('«حفظ» does nothing while the form has a problem', () async {
    final bloc = await loadedBloc();
    await after(
      bloc,
      const ContractorBankDetailsChanged(
        ContractorBankDetailsDraft(
          beneficiaryName: 'مؤسسة البناء المتين',
          bankName: 'مصرف الراجحي',
          iban: 'SA0480000000608010167519',
        ),
      ),
      (s) => s.check != null,
    );

    bloc.add(const ContractorBankDetailsSubmitted());
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.isSaving, isFalse);
    expect(repository.added, isEmpty);
    await bloc.close();
  });

  test('the first «حفظ» adds the details and shows what was stored', () async {
    final bloc = await loadedBloc();
    await after(
      bloc,
      const ContractorBankDetailsChanged(typed),
      (s) => s.canSave,
    );
    final states = <ContractorBankDetailsState>[];
    final subscription = bloc.stream.listen(states.add);

    final state = await after(
      bloc,
      const ContractorBankDetailsSubmitted(),
      (s) => s.saved != null,
    );

    expect(states.first.isSaving, isTrue);
    expect(repository.added.single.iban, 'SA0380000000608010167519');
    expect(repository.added.single.beneficiaryName, 'مؤسسة البناء المتين');
    expect(repository.updated, isEmpty);
    expect(state.saved?.iban, 'SA0380000000608010167519');
    expect(state.showsForm, isFalse);
    expect(state.isSaving, isFalse);
    expect(state.message?.key, 'payments.contractor.saved');
    expect(state.message?.kind, ContractorBankDetailsMessageKind.success);
    await subscription.cancel();
    await bloc.close();
  });

  test('«تعديل» then «حفظ» changes the saved details', () async {
    repository.saved = saved;
    final bloc = await loadedBloc();

    var state = await after(
      bloc,
      const ContractorBankDetailsEditStarted(),
      (s) => s.isEditing,
    );
    expect(state.showsForm, isTrue);
    expect(state.canSave, isFalse);

    // The same details typed again: still nothing to save.
    state = await after(
      bloc,
      const ContractorBankDetailsChanged(typed),
      (s) => s.check != null,
    );
    expect(state.canSave, isFalse);

    await after(
      bloc,
      const ContractorBankDetailsChanged(otherBank),
      (s) => s.canSave,
    );
    state = await after(
      bloc,
      const ContractorBankDetailsSubmitted(),
      (s) => !s.isEditing,
    );

    expect(repository.updated.single.bankName, 'البنك الأهلي السعودي');
    expect(repository.added, isEmpty);
    expect(state.saved?.bankName, 'البنك الأهلي السعودي');
    expect(state.showsForm, isFalse);
    await bloc.close();
  });

  test('«إلغاء» goes back to the saved details without saving', () async {
    repository.saved = saved;
    final bloc = await loadedBloc();
    await after(
      bloc,
      const ContractorBankDetailsEditStarted(),
      (s) => s.isEditing,
    );
    await after(
      bloc,
      const ContractorBankDetailsChanged(otherBank),
      (s) => s.canSave,
    );

    final state = await after(
      bloc,
      const ContractorBankDetailsEditCancelled(),
      (s) => !s.isEditing,
    );

    expect(state.showsForm, isFalse);
    expect(state.check, isNull);
    expect(state.saved, same(saved));
    expect(repository.updated, isEmpty);
    await bloc.close();
  });

  test('details added meanwhile (23505) show instead of the form', () async {
    final bloc = await loadedBloc();
    // Another device adds them after the page loaded.
    const fromOtherDevice = ContractorBankDetails(
      beneficiaryName: 'مؤسسة البناء المتين',
      bankName: 'البنك الأهلي السعودي',
      iban: 'SA0380000000608010167519',
    );
    repository
      ..saved = fromOtherDevice
      ..addResult = const Failed(ConflictFailure());
    await after(
      bloc,
      const ContractorBankDetailsChanged(typed),
      (s) => s.canSave,
    );

    final state = await after(
      bloc,
      const ContractorBankDetailsSubmitted(),
      (s) => s.saved != null,
    );

    expect(state.saved, same(fromOtherDevice));
    expect(state.showsForm, isFalse);
    expect(state.message?.key, 'payments.contractor.already_saved');
    expect(state.message?.kind, ContractorBankDetailsMessageKind.info);
    await bloc.close();
  });

  test('a suspended contractor (42501) stays in the form, told why', () async {
    repository.saved = saved;
    final bloc = await loadedBloc();
    await after(
      bloc,
      const ContractorBankDetailsEditStarted(),
      (s) => s.isEditing,
    );
    await after(
      bloc,
      const ContractorBankDetailsChanged(otherBank),
      (s) => s.canSave,
    );
    repository.updateResult = const Failed(PermissionFailure());

    final state = await after(
      bloc,
      const ContractorBankDetailsSubmitted(),
      (s) => s.message != null,
    );

    expect(state.isSaving, isFalse);
    expect(state.showsForm, isTrue);
    expect(state.canSave, isTrue);
    expect(state.message?.key, 'errors.permission');
    expect(state.message?.kind, ContractorBankDetailsMessageKind.error);
    expect(state.saved, same(saved));
    await bloc.close();
  });
}
