import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

String authErrorMessage(Object error) {
  final description = error.toString().toLowerCase();
  if (description.contains('certificate_verify_failed') ||
      description.contains('handshakeexception')) {
    return 'A secure connection could not be established. Check your phone’s '
        'date and time, then try again. If they are correct, check your network. '
        'Do not disable certificate verification.';
  }
  if (description.contains('invalid api key') ||
      description.contains('no api key found')) {
    return 'The app’s Supabase configuration was rejected. Check the project '
        'URL and publishable key in the run configuration, then rebuild the app.';
  }
  if (error is TimeoutException ||
      description.contains('socketexception') ||
      description.contains('clientexception') ||
      description.contains('failed host lookup') ||
      description.contains('network is unreachable')) {
    return 'Unable to reach Supabase. Internet may work for other apps while '
        'this connection is unavailable. Check the emulator network and try again.';
  }
  if (error is AuthException) return error.message;
  if (error is PostgrestException) {
    return 'Your account profile could not be loaded. Try again or contact '
        'the system administrator.';
  }
  return 'Unable to complete this request. Please try again.';
}
