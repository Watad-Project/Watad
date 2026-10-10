import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watad/app.dart';
import 'package:watad/core/config/env.dart';
import 'package:watad/core/di/injection.dart';
import 'package:watad/core/localization/app_localization.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Reads the language saved on the phone, so the app reopens in it.
  await EasyLocalization.ensureInitialized();
  // The public Supabase URL and publishable key (AGENTS.md §3).
  await dotenv.load();
  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabasePublishableKey,
  );
  configureDependencies();
  runApp(AppLocalization.scope(child: const WatadApp()));
}
