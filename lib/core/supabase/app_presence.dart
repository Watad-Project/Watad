import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The signed-in user's presence, kept up on its own (ARCHITECTURE.md §14):
///
/// * live: tracked on the private Realtime channel `online`, so screens can
///   show who is online now;
/// * saved: `set_my_presence(true)` every minute while the app is open, and
///   `false` when it goes to the background or the user signs out. The
///   server uses it to send an in-app notification instead of a push.
///
/// Started once, from main(), by `startAppServices()`.
abstract interface class AppPresence {
  /// The ids of the users online now, live. Empty while signed out.
  ValueListenable<Set<String>> get onlineUserIds;

  void start();

  /// Stops tracking; the saved presence then expires on its own.
  Future<void> stop();
}

class SupabaseAppPresence with WidgetsBindingObserver implements AppPresence {
  SupabaseAppPresence(this._client);

  final SupabaseClient _client;

  /// How often an open app says it's still there; the server counts a user
  /// online for two minutes after each call.
  static const Duration _heartbeat = Duration(minutes: 1);

  final ValueNotifier<Set<String>> _online = ValueNotifier(const {});
  StreamSubscription<AuthState>? _auth;
  RealtimeChannel? _channel;
  Timer? _timer;
  String? _userId;
  bool _inForeground = true;

  @override
  ValueListenable<Set<String>> get onlineUserIds => _online;

  @override
  void start() {
    if (_auth != null) return;
    WidgetsBinding.instance.addObserver(this);
    _auth = _client.auth.onAuthStateChange.listen(
      (change) => _setUser(change.session?.user.id),
    );
    _setUser(_client.auth.currentUser?.id);
  }

  @override
  Future<void> stop() async {
    WidgetsBinding.instance.removeObserver(this);
    await _auth?.cancel();
    _auth = null;
    _goOffline();
    _userId = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final inForeground = state == AppLifecycleState.resumed;
    if (inForeground == _inForeground) return;
    _inForeground = inForeground;
    inForeground ? _goOnline() : _goOffline();
  }

  void _setUser(String? userId) {
    if (userId == _userId) return; // e.g. a token refresh
    _goOffline();
    _userId = userId;
    if (_inForeground) _goOnline();
  }

  void _goOnline() {
    final userId = _userId;
    if (userId == null || _channel != null) return;
    _save(online: true);
    _timer = Timer.periodic(_heartbeat, (_) => _save(online: true));
    final channel = _client.channel(
      'online',
      opts: const RealtimeChannelConfig(private: true),
    );
    channel
        .onPresenceSync((_) {
          _online.value = {
            for (final state in channel.presenceState())
              for (final presence in state.presences)
                if (presence.payload['user_id'] case final String id) id,
          };
        })
        .subscribe((status, _) {
          if (status == RealtimeSubscribeStatus.subscribed) {
            unawaited(channel.track({'user_id': userId}));
          }
        });
    _channel = channel;
  }

  void _goOffline() {
    _timer?.cancel();
    _timer = null;
    final channel = _channel;
    _channel = null;
    if (channel != null) unawaited(_client.removeChannel(channel));
    _online.value = const {};
    // While still signed in (going to the background); after a sign-out the
    // saved presence simply expires.
    if (_userId != null && _client.auth.currentSession != null) {
      _save(online: false);
    }
  }

  /// Presence is best effort: a failed call is retried by the next one.
  void _save({required bool online}) {
    unawaited(
      _client
          .rpc<void>('set_my_presence', params: {'p_online': online})
          .then<void>((_) {}, onError: (Object _) {}),
    );
  }
}
