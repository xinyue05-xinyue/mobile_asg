import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_asg/app/theme/app_theme.dart';

void main() {
  testWidgets('filled buttons can render inside a row', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Row(
            children: [
              FilledButton(onPressed: () {}, child: const Text('Register')),
              const SizedBox(width: 8),
              FilledButton(onPressed: () {}, child: const Text('Details')),
            ],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Register'), findsOneWidget);
    expect(find.text('Details'), findsOneWidget);
  });

  test('staff role themes use visibly different accent colours', () {
    expect(
      AppTheme.forRole(AppTheme.organisation).colorScheme.primary,
      isNot(AppTheme.forRole(AppTheme.hospital).colorScheme.primary),
    );
    expect(
      AppTheme.forRole(AppTheme.hospital).colorScheme.primary,
      isNot(AppTheme.forRole(AppTheme.systemAdmin).colorScheme.primary),
    );
  });
}
