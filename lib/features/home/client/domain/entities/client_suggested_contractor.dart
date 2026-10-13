/// A suggested verified contractor shown on the client home screen.
class ClientSuggestedContractor {
  const ClientSuggestedContractor({
    required this.id,
    required this.companyName,
    this.avatarPath,
    this.specializedField,
    this.ratingLabel = '—',
    this.projectsLabel = '—',
    this.isVerified = true,
  });

  final String id;
  final String companyName;
  final String? avatarPath;
  final String? specializedField;
  final String ratingLabel;
  final String projectsLabel;
  final bool isVerified;
}
