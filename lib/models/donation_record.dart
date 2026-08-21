class DonationRecord {
  const DonationRecord({
    required this.id,
    required this.donationDate,
    required this.verificationStatus,
  });

  final String id;
  final DateTime donationDate;
  final String verificationStatus;

  factory DonationRecord.fromMap(Map<String, Object?> map) => DonationRecord(
    id: map['id']! as String,
    donationDate: DateTime.parse(map['donation_date']! as String),
    verificationStatus: map['verification_status']! as String,
  );
}
