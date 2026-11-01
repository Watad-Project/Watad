import 'package:watad/core/error/failure.dart';

/// How one part of «حفظ» went (GRA-60): the account (`users`) or the
/// business (`businesses`).
sealed class ProfileSavePart {
  const ProfileSavePart();
}

/// Nothing in this part changed, so nothing was sent.
final class ProfileSavePartUnchanged extends ProfileSavePart {
  const ProfileSavePartUnchanged();
}

/// The server stored it.
final class ProfileSavePartSaved extends ProfileSavePart {
  const ProfileSavePartSaved();
}

/// The server refused it, or it didn't get there.
final class ProfileSavePartFailed extends ProfileSavePart {
  const ProfileSavePartFailed(this.failure);

  final Failure failure;
}
