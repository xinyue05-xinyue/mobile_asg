import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_asg/main.dart';

void main() {
  testWidgets('shows the MyDarah welcome screen', (tester) async {
    await tester.pumpWidget(const MyDarahApp());

    expect(find.text('MyDarah'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });
}
