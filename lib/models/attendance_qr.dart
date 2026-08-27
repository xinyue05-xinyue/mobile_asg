/// Parses event-specific QR identifiers; authorisation remains server-side.
class AttendanceQr {
  static final _pattern = RegExp(
    r'^mydarah:event:([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}):donor:([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})$',
  );

  static String donorForEvent(String? value, String eventId) {
    final match = value == null ? null : _pattern.firstMatch(value.trim());
    if (match == null) {
      throw const FormatException('This is not a valid MyDarah donor QR.');
    }
    if (match.group(1)!.toLowerCase() != eventId.toLowerCase()) {
      throw const FormatException(
        'This QR belongs to a different event. Ask the donor to open the QR for this event.',
      );
    }
    return match.group(2)!.toLowerCase();
  }
}
