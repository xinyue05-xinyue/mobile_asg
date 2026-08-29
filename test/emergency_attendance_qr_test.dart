import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_asg/models/emergency_attendance_qr.dart';

void main() {
  const request = '11111111-1111-1111-8111-111111111111';
  const donor = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';

  test('emergency QR is request-specific and identifies its donor', () {
    final qr = EmergencyAttendanceQr(requestId: request, donorId: donor);
    final parsed = EmergencyAttendanceQr.tryParse(qr.value);
    expect(parsed?.requestId, request);
    expect(parsed?.donorId, donor);
  });

  test('arbitrary and event QR values are rejected', () {
    expect(EmergencyAttendanceQr.tryParse('https://example.com'), isNull);
    expect(
      EmergencyAttendanceQr.tryParse('mydarah:event:$request:donor:$donor'),
      isNull,
    );
  });
}
