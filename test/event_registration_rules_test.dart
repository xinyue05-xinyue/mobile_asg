import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_asg/models/donation_event.dart';
import 'package:mobile_asg/models/user_feedback.dart';

void main() {
  final event = DonationEvent(
    id: 'e',
    title: 'Testing',
    venue: 'Venue',
    startsAt: DateTime(2026, 8, 26),
    endsAt: DateTime(2026, 9, 2),
    status: 'upcoming',
  );
  test('registration stays open during an event and closes at its end', () {
    expect(event.registrationOpenAt(DateTime(2026, 8, 28)), isTrue);
    expect(event.registrationOpenAt(DateTime(2026, 9, 2)), isFalse);
    expect(event.registrationOpenAt(DateTime(2026, 9, 3)), isFalse);
  });
  test('donor with November eligibility cannot register for August event', () {
    expect(event.eligibleOnEventDate(DateTime(2026, 11, 23)), isFalse);
    expect(event.eligibleOnEventDate(DateTime(2026, 8, 26)), isTrue);
    expect(event.eligibleOnEventDate(null), isTrue);
  });
  test('feedback status labels preserve database values', () {
    UserFeedback feedback(String status) => UserFeedback(
      id: 'f',
      userId: 'u',
      userName: 'Donor',
      userRole: 'donor',
      category: 'general',
      message: 'Test feedback',
      status: status,
      createdAt: DateTime(2026),
    );
    expect(feedback('open').statusLabel, 'Submitted');
    expect(feedback('reviewed').statusLabel, 'Reviewed');
    expect(feedback('resolved').statusLabel, 'Resolved');
    expect(feedback('open').status, 'open');
  });
}
