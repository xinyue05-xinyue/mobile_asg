import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_asg/screens/staff_shell.dart';
import 'package:mobile_asg/widgets/profile_actions.dart';

void main() {
  testWidgets('staff navigation switches between main and profile', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: StaffShell(
          mainPage: Scaffold(body: Text('Dashboard content')),
          profilePage: Scaffold(body: Text('Profile content')),
        ),
      ),
    );
    expect(find.text('Dashboard content'), findsOneWidget);
    expect(find.text('Profile content'), findsNothing);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Profile content'), findsOneWidget);
    expect(find.text('Dashboard content'), findsNothing);
    await tester.tap(find.text('Main'));
    await tester.pumpAndSettle();
    expect(find.text('Dashboard content'), findsOneWidget);
  });

  testWidgets('system admin profile includes inbox and logout confirmation', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(actions: const [ProfileLogoutButton()]),
          body: const ProfileActions(isSystemAdmin: true),
        ),
      ),
    );
    expect(find.text('Feedback inbox'), findsOneWidget);
    expect(find.text('Send feedback'), findsNothing);
    await tester.tap(find.byTooltip('Log out'));
    await tester.pumpAndSettle();
    expect(find.text('Log out?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Log out?'), findsNothing);
    expect(find.text('Feedback inbox'), findsOneWidget);
  });
}
