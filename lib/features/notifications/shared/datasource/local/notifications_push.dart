import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watad/features/notifications/shared/datasource/local/notifications_push_mobile.dart'
    if (dart.library.js_interop) 'package:watad/features/notifications/shared/datasource/local/notifications_push_web.dart'
    as platform;

/// Push on this device, through OneSignal: Android and iOS with
/// `onesignal_flutter`, the web with the OneSignal Web SDK of
/// `web/index.html`. The device is signed in as the Supabase user
/// (`external_id` = user id), so the server's pushes reach them
/// (ARCHITECTURE.md §13).
abstract interface class NotificationsPush {
  /// The push of this platform; one that does nothing without an App ID.
  factory NotificationsPush(String? appId, SupabaseClient client) =>
      appId == null ? const _NoPush() : platform.createPush(appId, client);

  /// Starts OneSignal once (at launch, from `startAppServices()`), and keeps
  /// the device signed in as whoever is signed in to Supabase. Calling it
  /// again returns the same start.
  Future<void> start();

  /// Asks the user, once, to allow notifications.
  Future<void> requestPermission();

  /// The data of each tapped push, from its `data` (ARCHITECTURE.md §13).
  /// A tap that opened the app is delivered to the first listener.
  Stream<Map<String, dynamic>> get taps;

  Future<void> stop();
}

/// Without a OneSignal App ID (`.env`): no push, and nothing breaks.
class _NoPush implements NotificationsPush {
  const _NoPush();

  @override
  Future<void> start() async {}

  @override
  Future<void> requestPermission() async {}

  @override
  Stream<Map<String, dynamic>> get taps => const Stream.empty();

  @override
  Future<void> stop() async {}
}
