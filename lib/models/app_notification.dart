class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.referenceType,
    this.referenceId,
  });

  final String id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;
  final String? referenceType;
  final String? referenceId;

  factory AppNotification.fromMap(Map<String, Object?> map) => AppNotification(
    id: map['id']! as String,
    title: map['title']! as String,
    message: map['message']! as String,
    type: map['type']! as String,
    isRead: map['is_read']! as bool,
    createdAt: DateTime.parse(map['created_at']! as String).toLocal(),
    referenceType: map['reference_type'] as String?,
    referenceId: map['reference_id'] as String?,
  );
}
