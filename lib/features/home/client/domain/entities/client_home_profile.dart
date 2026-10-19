/// Who the home screen greets.
class ClientHomeProfile {
  const ClientHomeProfile({
    required this.fullName,
    required this.isPhoneVerified,
  });

  /// Empty when the client hasn't given a name.
  final String fullName;

  /// The phone number was confirmed with a code (Supabase Auth), not only
  /// typed in.
  final bool isPhoneVerified;
}
