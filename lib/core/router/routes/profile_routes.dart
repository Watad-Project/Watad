/// The routes of lib/features/profile/shared/. Any feature navigates to
/// them with these names (APP_ARCHITECTURE.md §11).
///
/// A public profile at `/profile/:userId` (GRA-58) goes after
/// [profileEditPath] in the routes list, so «edit» isn't read as a user id.
abstract final class ProfileRoutes {
  static const String profileEditName = 'profile-edit';
  static const String profileEditPath = '/profile/edit';
}
