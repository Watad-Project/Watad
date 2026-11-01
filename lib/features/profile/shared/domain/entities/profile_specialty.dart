/// The specialties a contractor picks from: GRA-16's five choices, in the
/// same order.
///
/// GRA-16 saves the chosen label in the language the app had at the time
/// («مقاولات عامة» or "General Contracting"), not a key, and the sign-up
/// form saved `contractor` before that. So a stored specialty is
/// recognised by comparing it with each choice's labels in both languages.
enum ProfileSpecialty {
  generalContracting,
  finishes,
  electricalPlumbing,
  renovation,
  insulation;

  /// The sign-up form's default. Like `AppSession`, it counts as no
  /// specialty yet.
  static const String signUpDefault = 'contractor';

  /// Whether [stored] names no specialty: empty, or [signUpDefault].
  static bool isUnset(String stored) {
    final text = stored.trim();
    return text.isEmpty || text == signUpDefault;
  }

  /// The choice [stored] is a label of, or null when it's unset or matches
  /// no choice (e.g. a typo). [labelsOf] gives a choice's labels: its text
  /// in Arabic and in English.
  static ProfileSpecialty? match(
    String stored,
    Iterable<String> Function(ProfileSpecialty choice) labelsOf,
  ) {
    if (isUnset(stored)) return null;
    final text = stored.trim();
    for (final choice in values) {
      if (labelsOf(choice).any((label) => label.trim() == text)) {
        return choice;
      }
    }
    return null;
  }
}
