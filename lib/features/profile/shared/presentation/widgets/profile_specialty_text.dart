import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:watad/features/profile/shared/domain/entities/profile_specialty.dart';

/// How the profile screens write a specialty (GRA-59, GRA-60). The labels
/// are GRA-16's own keys, so what's shown and saved here reads exactly
/// like what GRA-16 saves.
abstract final class ProfileSpecialtyText {
  /// The key of [choice]'s label in the app's language.
  static String labelKey(ProfileSpecialty choice) => switch (choice) {
    ProfileSpecialty.generalContracting =>
      'onboarding.specialty_general_contracting',
    ProfileSpecialty.finishes => 'onboarding.specialty_finishes',
    ProfileSpecialty.electricalPlumbing =>
      'onboarding.specialty_electrical_plumbing',
    ProfileSpecialty.renovation => 'onboarding.specialty_renovation',
    ProfileSpecialty.insulation => 'onboarding.specialty_insulation',
  };

  /// The keys of [choice]'s label as GRA-16 saved it in Arabic and in
  /// English. Both language files hold the same two texts, so a specialty
  /// saved in either language is recognised in both.
  static List<String> savedAsKeys(ProfileSpecialty choice) => switch (choice) {
    ProfileSpecialty.generalContracting => const [
      'profile.contractor.specialty_saved_as.general_contracting.ar',
      'profile.contractor.specialty_saved_as.general_contracting.en',
    ],
    ProfileSpecialty.finishes => const [
      'profile.contractor.specialty_saved_as.finishes.ar',
      'profile.contractor.specialty_saved_as.finishes.en',
    ],
    ProfileSpecialty.electricalPlumbing => const [
      'profile.contractor.specialty_saved_as.electrical_plumbing.ar',
      'profile.contractor.specialty_saved_as.electrical_plumbing.en',
    ],
    ProfileSpecialty.renovation => const [
      'profile.contractor.specialty_saved_as.renovation.ar',
      'profile.contractor.specialty_saved_as.renovation.en',
    ],
    ProfileSpecialty.insulation => const [
      'profile.contractor.specialty_saved_as.insulation.ar',
      'profile.contractor.specialty_saved_as.insulation.en',
    ],
  };

  /// The choice [stored] is a label of, in either language; null when it
  /// isn't one (unset, or a typo).
  static ProfileSpecialty? choiceOf(BuildContext context, String stored) =>
      ProfileSpecialty.match(
        stored,
        (choice) => [
          context.tr(labelKey(choice)),
          for (final key in savedAsKeys(choice)) context.tr(key),
        ],
      );

  /// [stored] as the screens show it: its choice's label in the app's
  /// language, the stored text itself when it's no choice, or null when no
  /// specialty is set.
  static String? of(BuildContext context, String stored) {
    if (ProfileSpecialty.isUnset(stored)) return null;
    final choice = choiceOf(context, stored);
    return choice == null ? stored.trim() : context.tr(labelKey(choice));
  }
}
