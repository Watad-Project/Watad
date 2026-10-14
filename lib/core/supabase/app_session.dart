import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
}

class SupabaseAppSession extends ChangeNotifier implements AppSession {
  SupabaseAppSession(this._client) : _userId = _client.auth.currentUser?.id {
    _subscription = _client.auth.onAuthStateChange.listen((change) {
      final userId = change.session?.user.id;
      if (userId == _userId) return; // e.g. a token refresh
      _userId = userId;
      _role = null;
      notifyListeners();
    });
  }

  final SupabaseClient _client;
  late final StreamSubscription<AuthState> _subscription;
  String? _userId;
  AppRole? _role;

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

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
