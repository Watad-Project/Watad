part of 'admin_review_documents_bloc.dart';

sealed class AdminReviewDocumentsState {
  const AdminReviewDocumentsState();
}

final class AdminReviewDocumentsInitial extends AdminReviewDocumentsState {
  const AdminReviewDocumentsInitial();
}

final class AdminReviewDocumentsLoadInProgress
    extends AdminReviewDocumentsState {
  const AdminReviewDocumentsLoadInProgress();
}

final class AdminReviewDocumentsLoadSuccess extends AdminReviewDocumentsState {
  const AdminReviewDocumentsLoadSuccess(this.documents);

  final List<AdminReviewDocument> documents;
}

final class AdminReviewDocumentsLoadFailure extends AdminReviewDocumentsState {
  const AdminReviewDocumentsLoadFailure(this.failure);

  final Failure failure;
}
