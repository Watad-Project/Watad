/// What the client narrows the contractors list to.
class ClientContractorFilter {
  const ClientContractorFilter({this.query = '', this.minRating});

  /// Part of the company name; empty matches every name.
  final String query;

  /// At least this average rating; null: any rating, including none yet.
  final double? minRating;

  ClientContractorFilter copyWith({
    String? query,
    double? Function()? minRating,
  }) {
    return ClientContractorFilter(
      query: query ?? this.query,
      minRating: minRating == null ? this.minRating : minRating(),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ClientContractorFilter &&
      other.query == query &&
      other.minRating == minRating;

  @override
  int get hashCode => Object.hash(query, minRating);
}
