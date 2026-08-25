class DonationRecord {
  const DonationRecord({
    required this.id,
    required this.donationDate,
    required this.verificationStatus,
    this.eventId,
    this.emergencyRequestId,
  });

  final String id;
  final DateTime donationDate;
  final String verificationStatus;
  final String? eventId;
  final String? emergencyRequestId;

  String get sourceLabel => emergencyRequestId != null
      ? 'Emergency donation'
      : eventId != null
      ? 'Donation event'
      : 'Blood donation';

  factory DonationRecord.fromMap(Map<String, Object?> map) => DonationRecord(
    id: map['id']! as String,
    donationDate: DateTime.parse(map['donation_date']! as String),
    verificationStatus: map['verification_status']! as String,
    eventId: map['event_id'] as String?,
    emergencyRequestId: map['emergency_request_id'] as String?,
  );
}
