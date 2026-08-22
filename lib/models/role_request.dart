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
    this.proofPath,
    this.proofPaths = const [],
    this.proofNames = const [],
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
  final String? proofPath;
  final List<String> proofPaths;
  final List<String> proofNames;

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
    proofPath: map['proof_path'] as String?,
    proofPaths: _stringList(map['proof_paths'], map['proof_path'] as String?),
    proofNames: _stringList(map['proof_names'], null),
  );

  String proofNameAt(int index) {
    if (index < proofNames.length && proofNames[index].isNotEmpty) {
      return proofNames[index];
    }
    return 'Supporting document ${index + 1}';
  }
}

List<String> _stringList(Object? value, String? fallback) {
  final items = value is List
      ? value.whereType<String>().where((item) => item.isNotEmpty).toList()
      : <String>[];
  if (items.isEmpty && fallback != null && fallback.isNotEmpty) {
    return [fallback];
  }
  return items;
}
