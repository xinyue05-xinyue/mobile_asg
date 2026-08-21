class GovernmentDonationStat {
  const GovernmentDonationStat({
    required this.date,
    required this.bloodType,
    required this.donations,
  });

  final DateTime date;
  final String bloodType;
  final int donations;

  Map<String, Object?> toMap() => {
    'date': date.toIso8601String().split('T').first,
    'blood_type': bloodType,
    'donations': donations,
  };

  factory GovernmentDonationStat.fromMap(Map<String, Object?> map) =>
      GovernmentDonationStat(
        date: DateTime.parse(map['date']! as String),
        bloodType: map['blood_type']! as String,
        donations: (map['donations']! as num).toInt(),
      );
}
