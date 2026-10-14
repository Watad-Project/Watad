import 'package:flutter/foundation.dart';
import 'package:watad/core/supabase/app_session.dart';

/// A hand-written [AppSession] (APP_ARCHITECTURE.md §16): signed out until
/// the test calls [signIn]. Signing in or out tells the router, like a real
/// sign-in does.
class FakeAppSession extends ChangeNotifier implements AppSession {
  AppRole? _role;

  void signIn(AppRole role) {
    _role = role;
    notifyListeners();
  }

  void signOut() {
    _role = null;
    notifyListeners();
  }

  @override
  bool get isSignedIn => _role != null;

  @override
  Future<AppRole> role() async => _role!;
}
