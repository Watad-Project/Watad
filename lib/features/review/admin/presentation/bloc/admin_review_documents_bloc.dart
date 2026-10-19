import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';
import 'package:watad/features/review/admin/domain/entities/admin_review_document.dart';
import 'package:watad/features/review/admin/domain/usecases/admin_get_request_documents_use_case.dart';

part 'admin_review_documents_event.dart';
part 'admin_review_documents_state.dart';

/// The files of one request, each with a short-lived link.
class AdminReviewDocumentsBloc
    extends Bloc<AdminReviewDocumentsEvent, AdminReviewDocumentsState> {
  AdminReviewDocumentsBloc(this._getDocuments)
    : super(const AdminReviewDocumentsInitial()) {
    on<AdminReviewDocumentsFetched>(_onFetched);
  }

  final AdminGetRequestDocumentsUseCase _getDocuments;

  Future<void> _onFetched(
    AdminReviewDocumentsFetched event,
    Emitter<AdminReviewDocumentsState> emit,
  ) async {
    emit(const AdminReviewDocumentsLoadInProgress());
    final result = await _getDocuments(event.businessId);
    switch (result) {
      case Success(:final data):
        emit(AdminReviewDocumentsLoadSuccess(data));
      case Failed(:final failure):
        emit(AdminReviewDocumentsLoadFailure(failure));
    }
  }
}
