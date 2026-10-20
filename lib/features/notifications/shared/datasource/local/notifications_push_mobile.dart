import 'dart:async';

import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watad/features/notifications/shared/datasource/local/notifications_push.dart';

NotificationsPush createPush(String appId, SupabaseClient client) =>
    NotificationsPushMobile(appId, client);

/// Push on Android and iOS, with `onesignal_flutter`.
class NotificationsPushMobile implements NotificationsPush {
  NotificationsPushMobile(this._appId, this._client);

  final String _appId;
  final SupabaseClient _client;
  final StreamController<Map<String, dynamic>> _taps =
      StreamController.broadcast();
  StreamSubscription<AuthState>? _auth;
  Map<String, dynamic>? _pendingTap;
  String? _userId;

  @override
  Future<void> start() async {
    if (_auth != null) return;
    await OneSignal.initialize(_appId);
    OneSignal.Notifications.addClickListener((event) {
      final data = event.notification.additionalData ?? const {};
      // A tap that opened the app comes before anyone listens: keep it.
      if (_taps.hasListener) {
        _taps.add(data);
      } else {
        _pendingTap = data;
      }
    });
    _auth = _client.auth.onAuthStateChange.listen(
      (change) => unawaited(_signIn(change.session?.user.id)),
    );
    await _signIn(_client.auth.currentUser?.id);
  }

  Future<void> _signIn(String? userId) async {
    if (userId == _userId) return;
    _userId = userId;
    userId == null ? await OneSignal.logout() : await OneSignal.login(userId);
  }

  @override
  Future<void> requestPermission() async {
    if (OneSignal.Notifications.permission) return;
    await OneSignal.Notifications.requestPermission(false);
  }

  @override
  Stream<Map<String, dynamic>> get taps async* {
    final pending = _pendingTap;
    _pendingTap = null;
    if (pending != null) yield pending;
    yield* _taps.stream;
  }

  @override
  Future<void> stop() async {
    await _auth?.cancel();
    _auth = null;
  }
}
