import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/kyc/contractor/domain/entities/contractor_license_submission.dart';
import 'package:watad/features/kyc/contractor/domain/repositories/contractor_kyc_repository.dart';
import 'package:watad/features/kyc/contractor/domain/usecases/contractor_sign_out_use_case.dart';
import 'package:watad/features/kyc/contractor/domain/usecases/contractor_upload_license_use_case.dart';
import 'package:watad/features/kyc/contractor/presentation/bloc/contractor_license_bloc.dart';

class FakeContractorKycRepository implements ContractorKycRepository {
  FakeContractorKycRepository(
    this.result, {
    this.signOutResult = const Success(null),
  });

  final Result<ContractorLicenseSubmission> result;
  final Result<void> signOutResult;
  int signOutCalls = 0;

  @override
  Future<Result<ContractorLicenseSubmission>> uploadLicense({
    required Uint8List bytes,
    required String fileName,
  }) async => result;

  @override
  Future<Result<void>> signOut() async {
    signOutCalls++;
    return signOutResult;
  }
}

ContractorLicenseBloc buildBloc(
  Result<ContractorLicenseSubmission> result, {
  Result<void> signOutResult = const Success(null),
}) {
  final repository = FakeContractorKycRepository(
    result,
    signOutResult: signOutResult,
  );
  final useCase = ContractorUploadLicenseUseCase(repository);
  final signOutUseCase = ContractorSignOutUseCase(repository);
  return ContractorLicenseBloc(useCase, signOutUseCase);
}

void main() {
  final sampleBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]);
  const sampleFileName = 'license.jpg';

  test('emits Ready when a file is selected', () async {
    final bloc = buildBloc(
      const Success(ContractorLicenseSubmission(storagePath: 'storage/path')),
    );

    final states = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<ContractorLicenseReady>().having(
          (s) => s.fileName,
          'fileName',
          sampleFileName,
        ),
      ]),
    );

    bloc.add(
      ContractorLicenseFileSelected(
        bytes: sampleBytes,
        fileName: sampleFileName,
      ),
    );

    await states;
    await bloc.close();
  });

  test('emits LoadInProgress then LoadSuccess on successful upload', () async {
    const submission = ContractorLicenseSubmission(storagePath: 'storage/path');
    final bloc = buildBloc(const Success(submission));

    bloc.add(
      ContractorLicenseFileSelected(
        bytes: sampleBytes,
        fileName: sampleFileName,
      ),
    );

    final states = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<ContractorLicenseReady>(),
        isA<ContractorLicenseLoadInProgress>(),
        isA<ContractorLicenseLoadSuccess>().having(
          (s) => s.submission.storagePath,
          'storagePath',
          'storage/path',
        ),
      ]),
    );

    bloc.add(const ContractorLicenseSubmitted());

    await states;
    await bloc.close();
  });

  test('emits LoadInProgress then LoadFailure on repository failure', () async {
    final bloc = buildBloc(const Failed(NetworkFailure()));

    bloc.add(
      ContractorLicenseFileSelected(
        bytes: sampleBytes,
        fileName: sampleFileName,
      ),
    );

    final states = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<ContractorLicenseReady>(),
        isA<ContractorLicenseLoadInProgress>(),
        isA<ContractorLicenseLoadFailure>(),
      ]),
    );

    bloc.add(const ContractorLicenseSubmitted());

    await states;
    await bloc.close();
  });

  test('emits LoadFailure directly if submitted without a file', () async {
    final bloc = buildBloc(
      const Success(ContractorLicenseSubmission(storagePath: 'storage/path')),
    );

    final states = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<ContractorLicenseLoadFailure>().having(
          (s) => s.failure.messageKey,
          'messageKey',
          'validation.file_required',
        ),
      ]),
    );

    bloc.add(const ContractorLicenseSubmitted());

    await states;
    await bloc.close();
  });

  test(
    'emits LoadInProgress then SignOutSuccess on successful sign out',
    () async {
      final bloc = buildBloc(
        const Success(ContractorLicenseSubmission(storagePath: 'storage/path')),
      );

      final states = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<ContractorLicenseLoadInProgress>(),
          isA<ContractorLicenseSignOutSuccess>(),
        ]),
      );

      bloc.add(const ContractorLicenseSignedOut());

      await states;
      await bloc.close();
    },
  );

  test('emits LoadInProgress then LoadFailure on sign out failure', () async {
    final bloc = buildBloc(
      const Success(ContractorLicenseSubmission(storagePath: 'storage/path')),
      signOutResult: const Failed(NetworkFailure()),
    );

    final states = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<ContractorLicenseLoadInProgress>(),
        isA<ContractorLicenseLoadFailure>(),
      ]),
    );

    bloc.add(const ContractorLicenseSignedOut());

    await states;
    await bloc.close();
  });
}
