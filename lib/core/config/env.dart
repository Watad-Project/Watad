import 'package:flutter_dotenv/flutter_dotenv.dart';

/// The app's configuration, read from `.env` once `main()` has loaded it.
///
/// `.env` is bundled into the app, so it holds only public values: the
/// Supabase URL and the publishable (anon) key. Copy it from `.env.example`
/// and ask a maintainer for the values (AGENTS.md §3). A missing value
/// throws at startup, naming the variable.
abstract final class Env {
  /// The Supabase project URL.
  static String get supabaseUrl => dotenv.get('SUPABASE_URL');

  /// The publishable (anon) key. Never the secret key.
  static String get supabasePublishableKey =>
      dotenv.get('SUPABASE_PUBLISHABLE_KEY');
}
