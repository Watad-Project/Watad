import 'package:flutter/foundation.dart';
import 'package:watad/core/router/routes/contractor_navigation_routes.dart';
import 'package:watad/core/supabase/app_session.dart';

/// A hand-written [AppSession] (APP_ARCHITECTURE.md §16): signed out until
/// the test calls [signIn]. Signing in or out tells the router, like a real
/// sign-in does.
class FakeAppSession extends ChangeNotifier implements AppSession {
  AppRole? _role;
  String? _contractorDestination;

  void signIn(AppRole role, [String? contractorDestination]) {
    _role = role;
    _contractorDestination = contractorDestination;
    notifyListeners();
  }

  void signOut() {
    _role = null;
    _contractorDestination = null;
    notifyListeners();
  }

  @override
  bool get isSignedIn => _role != null;

  @override
  Future<AppRole> role() async => _role!;

  @override
  Future<String> contractorDestination() async =>
      _contractorDestination ?? ContractorNavigationRoutes.navigationPath;
}
