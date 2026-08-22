class GovernmentDonationStat {
  const GovernmentDonationStat({
    required this.date,
    required this.state,
    required this.bloodType,
    required this.donations,
  });

  final DateTime date;
  final String state;
  final String bloodType;
  final int donations;

  Map<String, Object?> toMap() => {
    'date': date.toIso8601String().split('T').first,
    'state': state,
    'blood_type': bloodType,
    'donations': donations,
  };

  factory GovernmentDonationStat.fromMap(Map<String, Object?> map) =>
      GovernmentDonationStat(
        date: DateTime.parse(map['date']! as String),
        state: map['state'] as String? ?? 'Malaysia',
        bloodType: map['blood_type']! as String,
        donations: (map['donations']! as num).toInt(),
      );
}
