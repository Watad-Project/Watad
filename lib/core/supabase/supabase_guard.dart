import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watad/core/error/failure.dart';
import 'package:watad/core/error/result.dart';

/// Wraps an async call to Supabase, turning any exception into a [Failed]
/// with the appropriate [Failure].
Future<Result<T>> guardSupabaseCall<T>(Future<T> Function() call) async {
  try {
    final result = await call();
    return Success(result);
  } on AuthException catch (e) {
    return Failed(AuthFailure(e));
  } on SocketException catch (e) {
    return Failed(NetworkFailure(e));
  } catch (e) {
    return Failed(UnknownFailure(e));
  }
}
