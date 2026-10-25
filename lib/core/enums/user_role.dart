/// Mirror of the Postgres enum `app_role` (ARCHITECTURE.md §4): staff are
/// `admin`, everyone else is `user` (a client or, with a business, a
/// contractor).
enum UserRole {
  user('user'),
  admin('admin');

  const UserRole(this.value);

  final String value;

  static UserRole fromJson(String value) {
    return UserRole.values.firstWhere(
      (e) => e.value == value,
      orElse: () => UserRole.user,
    );
  }

  String toJson() => value;
}
