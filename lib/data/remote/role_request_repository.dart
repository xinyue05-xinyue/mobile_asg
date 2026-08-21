import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/role_request.dart';
import '../../models/user_role.dart';

class RoleRequestRepository {
  const RoleRequestRepository(this.client);

  final SupabaseClient client;

  Future<void> submit({
    required UserRole requestedRole,
    required String organisationName,
    required String staffPosition,
    required String reason,
  }) async {
    final user = client.auth.currentUser;
    if (user == null) throw const AuthException('Please log in again.');
    if (requestedRole != UserRole.admin && requestedRole != UserRole.hospital) {
      throw ArgumentError('Only admin or hospital access can be requested.');
    }

    await client.from('role_requests').insert({
      'user_id': user.id,
      'requested_role': requestedRole.databaseValue,
      'organisation_name': organisationName,
      'staff_position': staffPosition,
      'reason': reason,
    });
  }

  Future<List<RoleRequest>> getMine() async {
    final user = client.auth.currentUser;
    if (user == null) return const [];
    final rows = await client
        .from('role_requests')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);
    return rows.map(RoleRequest.fromMap).toList();
  }

  Future<List<RoleRequest>> getPending() async {
    final rows = await client
        .from('role_requests')
        .select()
        .eq('status', 'pending')
        .order('created_at');
    return rows.map(RoleRequest.fromMap).toList();
  }

  Future<void> review({
    required String requestId,
    required bool approve,
    String? rejectionReason,
  }) async {
    await client.rpc(
      'review_role_request',
      params: {
        'p_request_id': requestId,
        'p_approve': approve,
        'p_review_reason': rejectionReason,
      },
    );
  }
}
