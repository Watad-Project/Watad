part of 'admin_review_documents_bloc.dart';

sealed class AdminReviewDocumentsEvent {
  const AdminReviewDocumentsEvent();
}

final class AdminReviewDocumentsFetched extends AdminReviewDocumentsEvent {
  const AdminReviewDocumentsFetched(this.businessId);

  final String businessId;
}
