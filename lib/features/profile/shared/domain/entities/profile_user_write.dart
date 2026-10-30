/// One update of the signed-in user's `users` row (GRA-60): only the
/// columns that change are written.
class ProfileUserWrite {
  const ProfileUserWrite({
    this.fullName,
    this.changesAvatar = false,
    this.avatarPath,
  });

  /// The new name; null leaves it as it is.
  final String? fullName;

  /// Whether [avatarPath] is written: a new photo's path, or null to
  /// remove the photo.
  final bool changesAvatar;
  final String? avatarPath;
}
