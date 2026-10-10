import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/config/env.dart';

void main() {
  tearDown(dotenv.clean);

  test('reads the Supabase URL and publishable key from .env', () {
    dotenv.loadFromString(
      envString:
          'SUPABASE_URL=https://example.supabase.co\n'
          'SUPABASE_PUBLISHABLE_KEY=test-key',
    );

    expect(Env.supabaseUrl, 'https://example.supabase.co');
    expect(Env.supabasePublishableKey, 'test-key');
  });

  test('a missing value fails loudly, naming the variable', () {
    dotenv.loadFromString(
      envString: 'SUPABASE_URL=https://example.supabase.co',
    );

    expect(
      () => Env.supabasePublishableKey,
      throwsA(
        isA<AssertionError>().having(
          (error) => error.message,
          'message',
          contains('SUPABASE_PUBLISHABLE_KEY'),
        ),
      ),
    );
  });
}
