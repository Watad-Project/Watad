import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/enums/business_document_type.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_document.dart';
import 'package:watad/features/review/admin/domain/usecases/admin_get_request_documents_use_case.dart';
import 'package:watad/features/review/admin/presentation/bloc/admin_review_documents_bloc.dart';

import '../../../../../helpers/fake_admin_review_repository.dart';

void main() {
  late FakeAdminReviewRepository repository;

  AdminReviewDocumentsBloc buildBloc() =>
      AdminReviewDocumentsBloc(AdminGetRequestDocumentsUseCase(repository));

  setUp(() => repository = FakeAdminReviewRepository());

  test('loads the files of the request', () async {
    final document = AdminReviewDocument(
      id: 'doc-1',
      documentType: BusinessDocumentType.commercialRegistration,
      storagePath: 'b-1/license.pdf',
      createdAt: DateTime.utc(2026, 10, 18),
      url: 'https://example.supabase.co/x',
    );
    repository.documentsResult = Success([document]);
    final bloc = buildBloc();

    final states = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<AdminReviewDocumentsLoadInProgress>(),
        isA<AdminReviewDocumentsLoadSuccess>().having(
          (s) => s.documents,
          'documents',
          [document],
        ),
      ]),
    );
    bloc.add(const AdminReviewDocumentsFetched('b-1'));
    await states;
    await bloc.close();
  });

  test('shows the failure when the files cannot load', () async {
    repository.documentsResult = const Failed(ServerFailure());
    final bloc = buildBloc();

    final states = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<AdminReviewDocumentsLoadInProgress>(),
        isA<AdminReviewDocumentsLoadFailure>().having(
          (s) => s.failure,
          'failure',
          isA<ServerFailure>(),
        ),
      ]),
    );
    bloc.add(const AdminReviewDocumentsFetched('b-1'));
    await states;
    await bloc.close();
  });
}
