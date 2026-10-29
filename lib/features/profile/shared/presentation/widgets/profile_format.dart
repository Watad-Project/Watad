/// How the profile screens write a phone number (GRA-60).
abstract final class ProfileFormat {
  static final RegExp _saudiMobile = RegExp(r'^\+966(5\d)(\d{3})(\d{4})$');

  /// «+966 55 123 4567»: a Saudi mobile number as `user_identity` keeps it
  /// (`+9665XXXXXXXX`), in groups to read it out. Anything else stays as it
  /// is.
  static String phone(String phone) {
    final match = _saudiMobile.firstMatch(phone);
    if (match == null) return phone;
    return '+966 ${match[1]} ${match[2]} ${match[3]}';
  }
}
