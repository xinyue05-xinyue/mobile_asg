class UserFeedback {
  const UserFeedback({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.category,
    required this.message,
    required this.status,
    required this.createdAt,
    this.attachmentPaths = const [],
    this.attachmentNames = const [],
    this.adminResponse,
  });

  final String id;
  final String userId;
  final String userName;
  final String userRole;
  final String category;
  final String message;
  final String status;
  final DateTime createdAt;
  final List<String> attachmentPaths;
  final List<String> attachmentNames;
  final String? adminResponse;
  String get statusLabel => switch (status) {
    'open' => 'Submitted',
    'reviewed' => 'Reviewed',
    'resolved' => 'Resolved',
    _ => status,
  };

  factory UserFeedback.fromMap(Map<String, Object?> map) {
    final user = map['user'] as Map<String, Object?>?;
    return UserFeedback(
      id: map['id']! as String,
      userId: map['user_id']! as String,
      userName: user?['full_name'] as String? ?? 'User',
      userRole: user?['role']?.toString() ?? 'user',
      category: map['category']! as String,
      message: map['message']! as String,
      status: map['status']! as String,
      createdAt: DateTime.parse(map['created_at']! as String).toLocal(),
      attachmentPaths: (map['attachment_paths'] as List? ?? const [])
          .map((value) => value.toString())
          .toList(),
      attachmentNames: (map['attachment_names'] as List? ?? const [])
          .map((value) => value.toString())
          .toList(),
      adminResponse: map['admin_response'] as String?,
    );
  }
}
