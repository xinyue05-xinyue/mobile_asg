class OrganisationProfile {
  const OrganisationProfile({
    required this.ownerId,
    required this.displayName,
    this.contactPhone,
    this.address,
    this.description,
    this.latitude,
    this.longitude,
    this.imagePath,
  });

  final String ownerId;
  final String displayName;
  final String? contactPhone;
  final String? address;
  final String? description;
  final double? latitude;
  final double? longitude;
  final String? imagePath;

  factory OrganisationProfile.fromMap(Map<String, Object?> map) =>
      OrganisationProfile(
        ownerId: map['owner_id']! as String,
        displayName: map['display_name']! as String,
        contactPhone: map['contact_phone'] as String?,
        address: map['address'] as String?,
        description: map['description'] as String?,
        latitude: (map['latitude'] as num?)?.toDouble(),
        longitude: (map['longitude'] as num?)?.toDouble(),
        imagePath: map['image_path'] as String?,
      );
}
