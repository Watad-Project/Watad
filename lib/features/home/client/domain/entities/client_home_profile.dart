class ClientHomeProfile {
  const ClientHomeProfile({
    required this.fullName,
    required this.isPhoneVerified,
    this.avatarPath,
  });

  final String fullName;
  final bool isPhoneVerified;
  final String? avatarPath;
}
