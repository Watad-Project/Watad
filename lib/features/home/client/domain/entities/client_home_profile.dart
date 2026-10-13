/// The profile details of the signed-in client shown on their home screen.
class ClientHomeProfile {
  const ClientHomeProfile({
    required this.id,
    required this.fullName,
    required this.isPhoneVerified,
    this.avatarPath,
  });

  final String id;
  final String fullName;
  final bool isPhoneVerified;
  final String? avatarPath;
}
