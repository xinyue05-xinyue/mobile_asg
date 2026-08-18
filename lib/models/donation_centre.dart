class DonationCentre {
  const DonationCentre({
    required this.id,
    required this.name,
    required this.address,
    required this.state,
    required this.latitude,
    required this.longitude,
    this.operatingHours,
    this.sourceId,
  });

  final String id;
  final String name;
  final String address;
  final String state;
  final double latitude;
  final double longitude;
  final String? operatingHours;
  final String? sourceId;

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'address': address,
    'state': state,
    'latitude': latitude,
    'longitude': longitude,
    'operating_hours': operatingHours,
    'source_id': sourceId,
  };

  factory DonationCentre.fromMap(Map<String, Object?> map) => DonationCentre(
    id: map['id']! as String,
    name: map['name']! as String,
    address: map['address']! as String,
    state: map['state']! as String,
    latitude: (map['latitude']! as num).toDouble(),
    longitude: (map['longitude']! as num).toDouble(),
    operatingHours: map['operating_hours'] as String?,
    sourceId: map['source_id'] as String?,
  );
}
