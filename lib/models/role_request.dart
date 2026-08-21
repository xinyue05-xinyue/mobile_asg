import 'user_role.dart';

class RoleRequest {
  const RoleRequest({
    required this.id,
    required this.userId,
    required this.requestedRole,
    required this.organisationName,
    required this.staffPosition,
    required this.status,
    required this.createdAt,
    this.reason,
    this.rejectionReason,
  });

  final String id;
  final String userId;
  final UserRole requestedRole;
  final String organisationName;
  final String staffPosition;
  final String status;
  final DateTime createdAt;
  final String? reason;
  final String? rejectionReason;

  factory RoleRequest.fromMap(Map<String, Object?> map) => RoleRequest(
    id: map['id']! as String,
    userId: map['user_id']! as String,
    requestedRole: UserRole.fromDatabase(map['requested_role'] as String?),
    organisationName: map['organisation_name']! as String,
    staffPosition: map['staff_position']! as String,
    status: map['status']! as String,
    createdAt: DateTime.parse(map['created_at']! as String).toLocal(),
    reason: map['reason'] as String?,
    rejectionReason: map['rejection_reason'] as String?,
  );
}
