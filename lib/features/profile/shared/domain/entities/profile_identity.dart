/// The signed-in user's ID/iqama number and phone, from `v_my_identity`
/// (GRA-60). They're written once, at sign-up, and nothing changes them,
/// so the edit screen shows them read-only. Personal data: never log it.
class ProfileIdentity {
  const ProfileIdentity({required this.nationalId, required this.phone});

  /// 10 digits, starting with 1 or 2.
  final String nationalId;

  /// `+9665XXXXXXXX`.
  final String phone;
}
