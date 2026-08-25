class EventRegistration {
  const EventRegistration({
    required this.id,
    required this.eventId,
    required this.donorId,
    required this.status,
    required this.registeredAt,
    required this.donorName,
    required this.bloodType,
    this.phone,
    this.nextEligibleDate,
  });

  final String id;
  final String eventId;
  final String donorId;
  final String status;
  final DateTime registeredAt;
  final String donorName;
  final String? bloodType;
  final String? phone;
  final DateTime? nextEligibleDate;

  factory EventRegistration.fromMap(Map<String, Object?> map) {
    final donor = map['donor'] as Map<String, Object?>?;
    return EventRegistration(
      id: map['id']! as String,
      eventId: map['event_id']! as String,
      donorId: map['donor_id']! as String,
      status: map['status']! as String,
      registeredAt: DateTime.parse(map['registered_at']! as String).toLocal(),
      donorName: donor?['full_name'] as String? ?? 'Donor',
      bloodType: donor?['blood_type'] as String?,
      phone: donor?['phone'] as String?,
      nextEligibleDate: donor?['next_eligible_date'] == null
          ? null
          : DateTime.tryParse(donor!['next_eligible_date'] as String),
    );
  }
}
