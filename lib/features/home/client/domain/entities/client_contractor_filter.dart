import 'package:watad/features/home/client/domain/entities/client_contractor_sort.dart';

/// What the client narrows the contractors list to, and its order.
class ClientContractorFilter {
  const ClientContractorFilter({
    this.query = '',
    this.city,
    this.minRating,
    this.minProjects,
    this.sort = ClientContractorSort.rating,
  });

  /// Part of the company name; empty matches every name.
  final String query;

  /// Only contractors in this city; null: every city.
  final String? city;

  /// At least this average rating; null: any rating, including none yet.
  final double? minRating;

  /// At least this many completed projects; null: any number.
  final int? minProjects;

  final ClientContractorSort sort;

  /// How many filters of the filter sheet differ from the defaults (the
  /// name search is apart).
  int get sheetFilterCount => [
    city != null,
    minRating != null,
    minProjects != null,
    sort != ClientContractorSort.rating,
  ].where((isSet) => isSet).length;

  ClientContractorFilter copyWith({
    String? query,
    String? Function()? city,
    double? Function()? minRating,
    int? Function()? minProjects,
    ClientContractorSort? sort,
  }) {
    return ClientContractorFilter(
      query: query ?? this.query,
      city: city == null ? this.city : city(),
      minRating: minRating == null ? this.minRating : minRating(),
      minProjects: minProjects == null ? this.minProjects : minProjects(),
      sort: sort ?? this.sort,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ClientContractorFilter &&
      other.query == query &&
      other.city == city &&
      other.minRating == minRating &&
      other.minProjects == minProjects &&
      other.sort == sort;

  @override
  int get hashCode => Object.hash(query, city, minRating, minProjects, sort);
}
