class ClientSuggestedContractor {
  const ClientSuggestedContractor({
    required this.id,
    required this.companyName,
    required this.rating,
    required this.completedProjectsCount,
    required this.isVerified,
    this.avatarPath,
    this.specializedField,
  });

  final String id;
  final String companyName;
  final double rating;
  final int completedProjectsCount;
  final bool isVerified;
  final String? avatarPath;
  final String? specializedField;
}
