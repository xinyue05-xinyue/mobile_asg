class EmergencyAttendanceQr {
  const EmergencyAttendanceQr({required this.requestId, required this.donorId});

  final String requestId;
  final String donorId;

  String get value => 'mydarah:emergency:$requestId:donor:$donorId';

  static EmergencyAttendanceQr? tryParse(String value) {
    final parts = value.trim().split(':');
    if (parts.length != 5 ||
        parts[0] != 'mydarah' ||
        parts[1] != 'emergency' ||
        parts[3] != 'donor') {
      return null;
    }
    final uuid = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    if (!uuid.hasMatch(parts[2]) || !uuid.hasMatch(parts[4])) return null;
    return EmergencyAttendanceQr(requestId: parts[2], donorId: parts[4]);
  }
}
