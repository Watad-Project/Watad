/// The signed-in user, as the auth service returns them once a code is
/// verified. The session's tokens stay inside the Supabase client, which
/// sends them with every call; the app never handles them.
class AuthSession {
  const AuthSession({required this.userId, this.email});

  /// The user's id (`auth.users.id`, also `users.id`).
  final String userId;

  final String? email;
}
