class EmergencyResponse {
  const EmergencyResponse({
    required this.id,
    required this.requestId,
    required this.donorId,
    required this.status,
    required this.createdAt,
    required this.donorName,
    required this.bloodType,
  });

  final String id;
  final String requestId;
  final String donorId;
  final String status;
  final DateTime createdAt;
  final String donorName;
  final String? bloodType;

  factory EmergencyResponse.fromMap(Map<String, Object?> map) {
    final donor = map['donor'] as Map<String, Object?>?;
    return EmergencyResponse(
      id: map['id']! as String,
      requestId: map['request_id']! as String,
      donorId: map['donor_id']! as String,
      status: map['status']! as String,
      createdAt: DateTime.parse(map['created_at']! as String).toLocal(),
      donorName: donor?['full_name'] as String? ?? 'Donor',
      bloodType: donor?['blood_type'] as String?,
    );
  }
}
