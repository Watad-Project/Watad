/// My review of a project or an order, as saved.
class MyReview {
  const MyReview({required this.id, required this.rating, this.comment});

  final String id;

  /// From 1 to 5.
  final int rating;
  final String? comment;
}
