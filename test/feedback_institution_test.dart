import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mobile_asg/data/remote/feedback_repository.dart';
import 'package:mobile_asg/data/remote/remote_data_repository.dart';
import 'package:mobile_asg/models/donation_event.dart';
import 'package:mobile_asg/models/user_feedback.dart';
import 'package:mobile_asg/screens/feedback_detail_screen.dart';

void main() {
  test(
    'feedback saves separate replies through RPC, never overwrites directly',
    () async {
      final requests = <http.Request>[];
      final client = SupabaseClient(
        'https://example.supabase.co',
        'test-key',
        httpClient: MockClient((request) async {
          requests.add(request);
          return http.Response('', 204, request: request);
        }),
      );
      final repository = FeedbackRepository(client);
      await repository.review(
        id: 'f',
        status: 'reviewed',
        response: 'First reply',
      );
      await repository.review(
        id: 'f',
        status: 'resolved',
        response: 'Second reply',
      );
      expect(requests.length, 2);
      expect(
        requests.every(
          (r) =>
              r.method == 'POST' && r.url.path.endsWith('/rpc/review_feedback'),
        ),
        isTrue,
      );
      expect(jsonDecode(requests[0].body)['p_response'], 'First reply');
      expect(jsonDecode(requests[1].body)['p_response'], 'Second reply');
      await client.dispose();
    },
  );
  test(
    'different events keep the correct organiser and cache identity',
    () async {
      final client = SupabaseClient(
        'https://example.supabase.co',
        'test-key',
        httpClient: MockClient((request) async {
          final rows = request.url.path.endsWith('/donation_events')
              ? [
                  for (final owner in ['a', 'b'])
                    {
                      'id': owner,
                      'created_by': owner,
                      'title': 'Event $owner',
                      'venue': 'Venue',
                      'starts_at': '2026-08-28T01:00:00Z',
                      'ends_at': '2026-08-28T08:00:00Z',
                      'status': 'upcoming',
                    },
                ]
              : [
                  {'owner_id': 'a', 'display_name': 'Organisation A'},
                  {'owner_id': 'b', 'display_name': 'Organisation B'},
                ];
          return http.Response(
            jsonEncode(rows),
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      final events = await RemoteDataRepository(client).getEvents();
      expect(events[0].organiserName, 'Organisation A');
      expect(events[1].organiserName, 'Organisation B');
      final cached = DonationEvent.fromMap(events[1].toMap());
      expect(cached.createdBy, 'b');
      expect(cached.organiserName, 'Organisation B');
      await client.dispose();
    },
  );
  testWidgets('feedback has no manual refresh and retains legacy reply', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FeedbackDetailScreen(
          item: UserFeedback(
            id: 'f',
            userId: 'u',
            userName: 'Donor',
            userRole: 'donor',
            category: 'general',
            message: 'Feedback message',
            status: 'resolved',
            createdAt: DateTime(2026),
            adminResponse: 'Saved reply',
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byTooltip('Refresh'), findsNothing);
    expect(find.byType(RefreshIndicator), findsNothing);
    expect(find.text('Saved reply'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
