import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watad/core/router/routes/auth_routes.dart';
import 'package:watad/core/router/routes/contractor_kyc_routes.dart';
import 'package:watad/core/router/routes/contractor_navigation_routes.dart';
import 'package:watad/core/router/routes/contractor_onboarding_routes.dart';
import 'package:watad/core/router/routes/kyc_routes.dart';

/// Which role's area a signed-in user opens (APP_ARCHITECTURE.md §3).
enum AppRole {
  client,
  contractor,
  admin;

  /// The role of a `v_my_profile` row: staff (`users.role = 'admin'`) are
  /// admins, users with a business are contractors, everyone else is a
  /// client (ARCHITECTURE.md §2).
  static AppRole fromProfile(Map<String, dynamic> row) {
    if (row['is_admin'] as bool? ?? false) return admin;
    if (row['is_business'] as bool? ?? false) return contractor;
    return client;
  }
}

/// Who is signed in, and their role. The role is worked out only here, for
/// the router's guard; features never work it out (APP_ARCHITECTURE.md §3).
///
/// Listeners are told when the signed-in user changes (sign-in, sign-out),
/// so the router runs its guard again.
abstract interface class AppSession implements Listenable {
  bool get isSignedIn;

  /// The signed-in user's role. Read once per user.
  Future<AppRole> role();

  /// For a contractor, returns the destination path based on registration status.
  Future<String> contractorDestination();
}

class SupabaseAppSession extends ChangeNotifier implements AppSession {
  SupabaseAppSession(this._client) : _userId = _client.auth.currentUser?.id {
    _subscription = _client.auth.onAuthStateChange.listen((change) {
      final userId = change.session?.user.id;
      if (userId == _userId) return; // e.g. a token refresh
      _userId = userId;
      _role = null;
      _contractorDestination = null;
      notifyListeners();
    });
  }

  final SupabaseClient _client;
  late final StreamSubscription<AuthState> _subscription;
  String? _userId;
  AppRole? _role;
  String? _contractorDestination;

  @override
  bool get isSignedIn => _client.auth.currentSession != null;

  @override
  Future<AppRole> role() async {
    if (_role case final role?) return role;
    final userId = _userId;
    final row = await _client
        .from('v_my_profile')
        .select('is_admin, is_business')
        .maybeSingle();
    final role = AppRole.fromProfile(row ?? const {});
    // Keep it only if the same user is still signed in.
    if (userId == _userId) _role = role;
    return role;
  }

  /// Resolves the onboarding destination for a contractor based on registration status.
  static String resolveContractorDestination({
    required bool isBusiness,
    required Map<String, dynamic>? business,
    String? profileStatus,
    String? profileSpecializedField,
  }) {
    if (!isBusiness || business == null) {
      return AuthRoutes.signUpBusinessPath;
    }

    final statusStr =
        (business['verification_status'] ?? profileStatus) as String? ??
        'unverified';
    final specializedField =
        (business['specialized_field'] ?? profileSpecializedField) as String?;

    if (statusStr == 'unverified') {
      return ContractorKycRoutes.licensePath;
    }
    if (statusStr != 'verified') {
      return KycRoutes.statusPath;
    }
    if (specializedField == null ||
        specializedField.trim().isEmpty ||
        specializedField == 'contractor') {
      return ContractorOnboardingRoutes.specialtyPath;
    }
    return ContractorNavigationRoutes.navigationPath;
  }

  @override
  Future<String> contractorDestination() async {
    if (_contractorDestination case final dest?) return dest;
    final userId = _userId;
    if (userId == null) return ContractorNavigationRoutes.navigationPath;

    try {
      final profile = await _client
          .from('v_my_profile')
          .select('is_business, verification_status')
          .maybeSingle();

      final isBusiness = profile?['is_business'] as bool? ?? false;

      final business = await _client
          .from('businesses')
          .select('verification_status, specialized_field')
          .maybeSingle();

      final dest = resolveContractorDestination(
        isBusiness: isBusiness,
        business: business,
        profileStatus: profile?['verification_status'] as String?,
        profileSpecializedField: profile?['specialized_field'] as String?,
      );

      if (userId == _userId &&
          dest == ContractorNavigationRoutes.navigationPath) {
        _contractorDestination = dest;
      }
      return dest;
    } catch (_) {
      return ContractorNavigationRoutes.navigationPath;
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
