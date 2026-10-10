/// Represents an authenticated session.
class AuthSession {
  const AuthSession({required this.userId, this.accessToken, this.email});

  /// The unique ID of the authenticated user.
  final String userId;

  /// The JWT access token for Supabase requests.
  final String? accessToken;

  /// The email address of the authenticated user.
  final String? email;
}
