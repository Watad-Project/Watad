/// A verified contractor a client can find: a `v_public_profiles` row.
class ClientContractor {
  const ClientContractor({
    required this.id,
    required this.companyName,
    required this.ratingCount,
    this.ratingAvg,
    this.avatarUrl,
  });

  final String id;
  final String companyName;

  /// The average of their reviews; null before the first one.
  final double? ratingAvg;
  final int ratingCount;

  /// The public URL of their photo, if they have one.
  final String? avatarUrl;
}
