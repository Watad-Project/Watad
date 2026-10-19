/// Who the home screen greets.
class ClientHomeProfile {
  const ClientHomeProfile({
    required this.fullName,
    required this.isPhoneVerified,
    this.avatarUrl,
  });

  /// Empty when the client hasn't given a name.
  final String fullName;

  /// The phone number was confirmed with a code (Supabase Auth), not only
  /// typed in.
  final bool isPhoneVerified;

  /// The public URL of their photo; null shows the default avatar.
  final String? avatarUrl;
}
