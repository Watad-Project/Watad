import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/verification_status.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/kyc/shared/domain/entities/kyc_document.dart';
import 'package:watad/features/kyc/shared/domain/repositories/kyc_repository.dart';
import 'package:watad/features/kyc/shared/domain/usecases/get_kyc_document_use_case.dart';
import 'package:watad/features/kyc/shared/domain/usecases/watch_kyc_document_use_case.dart';
import 'package:watad/features/kyc/shared/presentation/bloc/kyc_status_bloc.dart';

class FakeKycRepository implements KycRepository {
  FakeKycRepository({
    required this.documentResult,
    Stream<Result<KycDocument>>? stream,
  }) : stream = stream ?? const Stream.empty();

  final Result<KycDocument> documentResult;
  final Stream<Result<KycDocument>> stream;

  @override
  Future<Result<KycDocument>> getDocument(KycDocumentType documentType) async =>
      documentResult;

  @override
  Stream<Result<KycDocument>> watchDocument(KycDocumentType documentType) =>
      stream;
}

KycStatusBloc buildBloc({
  required Result<KycDocument> result,
  Stream<Result<KycDocument>>? stream,
}) {
  final repository = FakeKycRepository(documentResult: result, stream: stream);
  return KycStatusBloc(
    GetKycDocumentUseCase(repository),
    WatchKycDocumentUseCase(repository),
  );
}

void main() {
  const sampleDocument = KycDocument(
    id: 'doc-1',
    documentType: KycDocumentType.license,
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

      bloc.add(const KycStatusStarted(documentType: KycDocumentType.license));

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
          documentType: KycDocumentType.license,
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

    bloc.add(const KycStatusStarted(documentType: KycDocumentType.license));

    await states;
    await bloc.close();
  });

  test('updates state when realtime stream yields new document', () async {
    final controller = StreamController<Result<KycDocument>>();
    final bloc = buildBloc(
      result: const Success(sampleDocument),
      stream: controller.stream,
    );

    const updatedDocument = KycDocument(
      id: 'doc-1',
      documentType: KycDocumentType.license,
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

    bloc.add(const KycStatusStarted(documentType: KycDocumentType.license));
    await pumpEventQueue();

    controller.add(const Success(updatedDocument));

    await states;
    await controller.close();
    await bloc.close();
  });
}
