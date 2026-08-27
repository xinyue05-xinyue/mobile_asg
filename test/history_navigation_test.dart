import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_asg/models/donation_record.dart';
import 'package:mobile_asg/models/reward_transaction.dart';
import 'package:mobile_asg/screens/donor/history_screens.dart';
import 'package:mobile_asg/widgets/event_schedule.dart';

void main() {
  test('schedule includes both dates for overnight events', () {
    expect(
      eventSchedule(DateTime(2026, 8, 28, 23), DateTime(2026, 8, 29, 1)),
      'Starts: 28/08/2026 23:00\nEnds: 29/08/2026 01:00',
    );
  });
  testWidgets('emergency donation opens a details page with retry on failure', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DonationHistoryScreen(
          donations: [
            DonationRecord(
              id: 'd',
              donationDate: DateTime(2026, 8, 28),
              verificationStatus: 'verified',
              emergencyRequestId: 'e',
            ),
          ],
        ),
      ),
    );
    await tester.tap(find.text('Emergency donation'));
    await tester.pumpAndSettle();
    expect(find.byType(HistoryDetailScreen), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('reward opens transaction details', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RewardHistoryScreen(
          rewards: [
            RewardTransaction(
              id: 'r',
              points: -200,
              transactionType: 'redeemed',
              createdAt: DateTime(2026, 8, 28),
            ),
          ],
        ),
      ),
    );
    await tester.tap(find.text('-200 points'));
    await tester.pumpAndSettle();
    expect(find.text('Reward details'), findsOneWidget);
    expect(find.text('Transaction reference'), findsOneWidget);
    expect(find.text('r'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
