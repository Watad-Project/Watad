import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watad/features/notifications/shared/datasource/local/notifications_push.dart';

NotificationsPush createPush(String appId, SupabaseClient client) =>
    NotificationsPushWeb(appId, client);

/// The queue of the OneSignal Web SDK (web/index.html): functions pushed on
/// it run once the SDK has loaded, with the SDK as their argument.
@JS('OneSignalDeferred')
external JSArray<JSFunction>? get _oneSignalDeferred;

/// Push in the browser, with the OneSignal Web SDK: `onesignal_flutter` has
/// no web version.
class NotificationsPushWeb implements NotificationsPush {
  NotificationsPushWeb(this._appId, this._client);

  final String _appId;
  final SupabaseClient _client;
  final StreamController<Map<String, dynamic>> _taps =
      StreamController.broadcast();
  final Completer<JSObject> _sdk = Completer();
  StreamSubscription<AuthState>? _auth;
  Map<String, dynamic>? _pendingTap;
  String? _userId;

  @override
  Future<void> start() async {
    if (_auth != null) return;
    final deferred = _oneSignalDeferred;
    // Without the SDK's script on the page, the web runs without push.
    if (deferred == null) return;
    deferred.callMethod(
      'push'.toJS,
      ((JSObject oneSignal) {
        unawaited(_init(oneSignal));
      }).toJS,
    );
    _auth = _client.auth.onAuthStateChange.listen(
      (change) => unawaited(_signIn(change.session?.user.id)),
    );
    await _signIn(_client.auth.currentUser?.id);
  }

  Future<void> _init(JSObject oneSignal) async {
    await oneSignal
        .callMethod<JSPromise>(
          'init'.toJS,
          {'appId': _appId, 'allowLocalhostAsSecureOrigin': true}.jsify(),
        )
        .toDart;
    final notifications = oneSignal.getProperty<JSObject>('Notifications'.toJS);
    notifications.callMethod(
      'addEventListener'.toJS,
      'click'.toJS,
      ((JSObject event) {
        final notification = event.getProperty<JSObject?>('notification'.toJS);
        final data = notification
            ?.getProperty<JSAny?>('additionalData'.toJS)
            .dartify();
        final tap = {
          if (data is Map)
            for (final entry in data.entries) '${entry.key}': entry.value,
        };
        if (_taps.hasListener) {
          _taps.add(tap);
        } else {
          _pendingTap = tap;
        }
      }).toJS,
    );
    _sdk.complete(oneSignal);
  }

  Future<void> _signIn(String? userId) async {
    if (userId == _userId) return;
    _userId = userId;
    final oneSignal = await _sdk.future;
    if (userId == null) {
      await oneSignal.callMethod<JSPromise>('logout'.toJS).toDart;
    } else {
      await oneSignal.callMethod<JSPromise>('login'.toJS, userId.toJS).toDart;
    }
  }

  @override
  Future<void> requestPermission() async {
    if (_oneSignalDeferred == null) return;
    final oneSignal = await _sdk.future;
    final notifications = oneSignal.getProperty<JSObject>('Notifications'.toJS);
    await notifications.callMethod<JSPromise>('requestPermission'.toJS).toDart;
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
