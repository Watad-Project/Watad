import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/business_document_type.dart';
import 'package:watad/core/enums/verification_status.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/kyc/shared/domain/entities/kyc_document.dart';
import 'package:watad/features/kyc/shared/domain/repositories/kyc_repository.dart';
import 'package:watad/features/kyc/shared/domain/usecases/get_kyc_document_use_case.dart';
import 'package:watad/features/kyc/shared/domain/usecases/sign_out_kyc_use_case.dart';
import 'package:watad/features/kyc/shared/domain/usecases/watch_kyc_document_use_case.dart';
import 'package:watad/features/kyc/shared/presentation/bloc/kyc_status_bloc.dart';

class FakeKycRepository implements KycRepository {
  FakeKycRepository({
    required this.documentResult,
    Stream<Result<KycDocument>>? stream,
    this.signOutResult = const Success(null),
  }) : stream = stream ?? const Stream.empty();

  Result<KycDocument> documentResult;
  final Stream<Result<KycDocument>> stream;
  final Result<void> signOutResult;
  int signOutCalls = 0;

  @override
  Future<Result<KycDocument>> getDocument([
    BusinessDocumentType documentType =
        BusinessDocumentType.commercialRegistration,
  ]) async => documentResult;

  @override
  Stream<Result<KycDocument>> watchDocument([
    BusinessDocumentType documentType =
        BusinessDocumentType.commercialRegistration,
  ]) => stream;

  @override
  Future<Result<void>> signOut() async {
    signOutCalls++;
    return signOutResult;
  }
}

KycStatusBloc buildBloc({
  required Result<KycDocument> result,
  Stream<Result<KycDocument>>? stream,
  Result<void> signOutResult = const Success(null),
}) {
  final repository = FakeKycRepository(
    documentResult: result,
    stream: stream,
    signOutResult: signOutResult,
  );
  return KycStatusBloc(
    GetKycDocumentUseCase(repository),
    WatchKycDocumentUseCase(repository),
    SignOutKycUseCase(repository),
  );
}

void main() {
  const sampleDocument = KycDocument(
    id: 'doc-1',
    documentType: BusinessDocumentType.commercialRegistration,
    status: VerificationStatus.pending,
  );

  test(
    'emits LoadInProgress then LoadSuccess on initial fetch success',
    () async {
      final bloc = buildBloc(result: const Success(sampleDocument));

      final states = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<KycStatusLoadInProgress>(),
          isA<KycStatusLoadSuccess>().having(
            (s) => s.document.status,
            'status',
            VerificationStatus.pending,
          ),
        ]),
      );

      bloc.add(
        const KycStatusStarted(
          documentType: BusinessDocumentType.commercialRegistration,
        ),
      );

      await states;
      await bloc.close();
    },
  );

  test(
    'emits LoadSuccess immediately when initialStatus is provided',
    () async {
      final bloc = buildBloc(result: const Success(sampleDocument));

      final states = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<KycStatusLoadSuccess>().having(
            (s) => s.document.status,
            'status',
            VerificationStatus.verified,
          ),
        ]),
      );

      bloc.add(
        const KycStatusStarted(
          documentType: BusinessDocumentType.commercialRegistration,
          initialStatus: VerificationStatus.verified,
        ),
      );

      await states;
      await bloc.close();
    },
  );

  test('emits LoadInProgress then LoadFailure on fetch error', () async {
    final bloc = buildBloc(result: const Failed(NetworkFailure()));

    final states = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<KycStatusLoadInProgress>(),
        isA<KycStatusLoadFailure>(),
      ]),
    );

    bloc.add(
      const KycStatusStarted(
        documentType: BusinessDocumentType.commercialRegistration,
      ),
    );

    await states;
    await bloc.close();
  });

  test(
    'refreshes status and completes completer on KycStatusRefreshed',
    () async {
      final repository = FakeKycRepository(
        documentResult: const Success(sampleDocument),
      );
      final bloc = KycStatusBloc(GetKycDocumentUseCase(repository));

      const updatedDocument = KycDocument(
        id: 'doc-1',
        documentType: BusinessDocumentType.commercialRegistration,
        status: VerificationStatus.verified,
      );

      final states = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<KycStatusLoadInProgress>(),
          isA<KycStatusLoadSuccess>().having(
            (s) => s.document.status,
            'status',
            VerificationStatus.pending,
          ),
          isA<KycStatusLoadSuccess>().having(
            (s) => s.document.status,
            'status',
            VerificationStatus.verified,
          ),
        ]),
      );

      bloc.add(
        const KycStatusStarted(
          documentType: BusinessDocumentType.commercialRegistration,
        ),
      );
      await pumpEventQueue();

      repository.documentResult = const Success(updatedDocument);

      final completer = Completer<void>();
      bloc.add(
        KycStatusRefreshed(
          documentType: BusinessDocumentType.commercialRegistration,
          completer: completer,
        ),
      );

      await completer.future;
      expect(completer.isCompleted, isTrue);

      await states;
      await bloc.close();
    },
  );

  test(
    'emits LoadInProgress then SignOutSuccess on successful sign out',
    () async {
      final bloc = buildBloc(result: const Success(sampleDocument));

      final states = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<KycStatusLoadInProgress>(),
          isA<KycStatusSignOutSuccess>(),
        ]),
      );

      bloc.add(const KycStatusSignedOut());

      await states;
      await bloc.close();
    },
  );

  test('emits LoadInProgress then LoadFailure on sign out failure', () async {
    final bloc = buildBloc(
      result: const Success(sampleDocument),
      signOutResult: const Failed(NetworkFailure()),
    );

    final states = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<KycStatusLoadInProgress>(),
        isA<KycStatusLoadFailure>(),
      ]),
    );

    bloc.add(const KycStatusSignedOut());

    await states;
    await bloc.close();
  });
}
