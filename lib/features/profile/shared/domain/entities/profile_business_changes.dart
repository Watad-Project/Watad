/// What changed in the business part of the edit form (GRA-60), saved to
/// the contractor's `businesses` row. Each value is null when it didn't
/// change, and is then not sent: the reset trigger and the chain's sync
/// react to a column that's sent, even unchanged.
class ProfileBusinessChanges {
  const ProfileBusinessChanges({
    this.companyName,
    this.crNumber,
    this.specializedField,
    this.city,
  });

  final String? companyName;
  final String? crNumber;
  final String? specializedField;
  final String? city;

  bool get isEmpty =>
      companyName == null &&
      crNumber == null &&
      specializedField == null &&
      city == null;
}
