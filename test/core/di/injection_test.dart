import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watad/core/di/injection.dart';

void main() {
  tearDown(getIt.reset);

  test('registers the Supabase client without touching Supabase', () {
    // Supabase is not initialized here: the registration must stay lazy.
    configureDependencies();

    expect(getIt.isRegistered<SupabaseClient>(), isTrue);
  });
}
