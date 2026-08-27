import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_asg/models/attendance_qr.dart';

void main() {
  const event = '11111111-1111-1111-1111-111111111111';
  const donor = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
  const qr = 'mydarah:event:$event:donor:$donor';
  test('valid QR identifies its donor for the selected event', () {
    expect(AttendanceQr.donorForEvent(qr, event), donor);
  });
  test('QR for another event is rejected', () {
    expect(
      () => AttendanceQr.donorForEvent(
        qr,
        '22222222-2222-2222-2222-222222222222',
      ),
      throwsFormatException,
    );
  });
  test(
    'missing, arbitrary, empty and malformed donor identifiers are rejected',
    () {
      for (final value in [
        null,
        '',
        'https://example.com',
        'mydarah:event:$event:donor:',
        'mydarah:event:$event:donor:not-a-uuid',
        '$qr:extra',
      ]) {
        expect(
          () => AttendanceQr.donorForEvent(value, event),
          throwsFormatException,
        );
      }
    },
  );
  test('UUID casing and outer whitespace are tolerated', () {
    expect(
      AttendanceQr.donorForEvent(
        '  mydarah:event:$event:donor:${donor.toUpperCase()}  ',
        event,
      ),
      donor,
    );
  });
}
