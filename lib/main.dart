import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:watad/app.dart';
import 'package:watad/core/localization/app_localization.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Reads the language saved on the phone, so the app reopens in it.
  await EasyLocalization.ensureInitialized();
  runApp(AppLocalization.scope(child: const WatadApp()));
}
