import 'package:watad/core/enums/verification_status.dart';
import 'package:watad/features/profile/shared/domain/entities/my_profile.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_business_changes.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_form_check.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_photo_change.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_user_changes.dart';

/// What differs between the saved profile and the edit form (GRA-60), and
/// what saving it does to the business's verification.
class ProfileChanges {
  const ProfileChanges({
    this.user = const ProfileUserChanges(),
    this.business = const ProfileBusinessChanges(),
    this.verificationStatus,
  });

  /// Compares the form ([check], and the picked [photo], [specializedField]
  /// and [city]) with [profile].
  ///
  /// A value counts as changed only when, trimmed, it differs from the
  /// saved one trimmed: the reset trigger compares the raw text, so a
  /// column that didn't really change is never sent. A verified business's
  /// CR number can't change (migration 86), so it never counts.
  factory ProfileChanges.between({
    required MyProfile profile,
    required ProfileFormCheck check,
    ProfilePhotoChange photo = const ProfilePhotoKept(),
    String? specializedField,
    String? city,
  }) {
    final business = profile.business;
    final status = business?.verificationStatus;
    return ProfileChanges(
      user: ProfileUserChanges(
        fullName: _changed(check.fullName, profile.fullName),
        photo: photo,
      ),
      business: business == null
          ? const ProfileBusinessChanges()
          : ProfileBusinessChanges(
              companyName: _changed(check.companyName, business.companyName),
              crNumber: status == VerificationStatus.verified
                  ? null
                  : _changed(check.crNumber, business.crNumber),
              specializedField: _changed(
                specializedField,
                business.specializedField,
              ),
              city: _changed(city, business.city),
            ),
      verificationStatus: status,
    );
  }

  final ProfileUserChanges user;
  final ProfileBusinessChanges business;

  /// The business's status when the form opened; null for a client.
  final VerificationStatus? verificationStatus;

  bool get isEmpty => user.isEmpty && business.isEmpty;

  /// Whether saving sends the business back to `unverified`: a new company
  /// name or CR number while it's `pending` or `verified`
  /// (`private.businesses_reset_verification()`, migration 02).
  bool get unverifiesBusiness =>
      (verificationStatus == VerificationStatus.pending ||
          verificationStatus == VerificationStatus.verified) &&
      (business.companyName != null || business.crNumber != null);

  /// [value] trimmed when it differs from [saved]; null when it's the same
  /// or wasn't given.
  static String? _changed(String? value, String? saved) {
    final text = value?.trim();
    if (text == null || text == saved?.trim()) return null;
    return text;
  }
}
