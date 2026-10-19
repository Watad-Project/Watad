/// A verified contractor a client can find: a `v_contractors` row.
class ClientContractor {
  const ClientContractor({
    required this.id,
    required this.companyName,
    required this.ratingCount,
    this.completedProjectCount = 0,
    this.isInMyCity = false,
    this.city,
    this.ratingAvg,
    this.avatarUrl,
  });

  final String id;
  final String companyName;

  /// Where the business works; null until the contractor sets it.
  final String? city;

  /// The average of their reviews; null before the first one.
  final double? ratingAvg;
  final int ratingCount;

  /// Projects they finished as the contractor.
  final int completedProjectCount;

  /// They work in the city of the client's latest saved address.
  final bool isInMyCity;

  /// The public URL of their photo, if they have one.
  final String? avatarUrl;
}
