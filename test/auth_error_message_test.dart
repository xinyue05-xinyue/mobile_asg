import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_asg/data/remote/auth_error_message.dart';
import 'package:mobile_asg/screens/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('certificate errors explain clock check', () {
    expect(
      authErrorMessage(Exception('CERTIFICATE_VERIFY_FAILED')),
      contains('date and time'),
    );
  });
  test('network errors are not described as invalid credentials', () {
    expect(
      authErrorMessage(Exception('SocketException: Network is unreachable')),
      contains('Unable to reach Supabase'),
    );
  });
  test('ordinary authentication errors retain their message', () {
    expect(
      authErrorMessage(const AuthException('Invalid login credentials')),
      'Invalid login credentials',
    );
  });
  test('unknown errors do not expose internal details', () {
    expect(
      authErrorMessage(Exception('sensitive internal details')),
      isNot(contains('sensitive')),
    );
  });
  testWidgets('missing configuration cannot log in as a donor', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await tester.enterText(find.byType(TextField).at(0), 'test@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'test-password');
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.textContaining('Login is unavailable.'), findsOneWidget);
  });
}
