class DonationEvent {
  const DonationEvent({
    required this.id,
    required this.title,
    required this.venue,
    required this.startsAt,
    required this.endsAt,
    required this.status,
    this.description,
    this.latitude,
    this.longitude,
    this.imagePath,
  });

  final String id;
  final String title;
  final String venue;
  final DateTime startsAt;
  final DateTime endsAt;
  final String status;
  final String? description;
  final double? latitude;
  final double? longitude;
  final String? imagePath;

  Map<String, Object?> toMap() => {
    'id': id,
    'title': title,
    'venue': venue,
    'starts_at': startsAt.toUtc().toIso8601String(),
    'ends_at': endsAt.toUtc().toIso8601String(),
    'status': status,
    'description': description,
    'latitude': latitude,
    'longitude': longitude,
    'image_path': imagePath,
  };

  factory DonationEvent.fromMap(Map<String, Object?> map) => DonationEvent(
    id: map['id']! as String,
    title: map['title']! as String,
    venue: map['venue']! as String,
    startsAt: DateTime.parse(map['starts_at']! as String).toLocal(),
    endsAt: DateTime.parse(map['ends_at']! as String).toLocal(),
    status: map['status']! as String,
    description: map['description'] as String?,
    latitude: (map['latitude'] as num?)?.toDouble(),
    longitude: (map['longitude'] as num?)?.toDouble(),
    imagePath: map['image_path'] as String?,
  );
}
