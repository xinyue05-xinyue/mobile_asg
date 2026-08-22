import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/role_request.dart';
import '../../models/user_role.dart';

class RoleRequestRepository {
  const RoleRequestRepository(this.client);

  final SupabaseClient client;

  static const proofBucket = 'role-request-proofs';

  Future<void> submit({
    required UserRole requestedRole,
    required String organisationName,
    required String staffPosition,
    required String reason,
    required Uint8List proofBytes,
    required String proofFileName,
  }) async {
    final user = client.auth.currentUser;
    if (user == null) throw const AuthException('Please log in again.');
    if (requestedRole != UserRole.admin && requestedRole != UserRole.hospital) {
      throw ArgumentError('Only admin or hospital access can be requested.');
    }

    final extension = _imageExtension(proofFileName);
    final proofPath =
        '${user.id}/${DateTime.now().microsecondsSinceEpoch}.$extension';

    await client.storage
        .from(proofBucket)
        .uploadBinary(
          proofPath,
          proofBytes,
          fileOptions: FileOptions(contentType: _contentType(extension)),
        );

    try {
      await client.from('role_requests').insert({
        'user_id': user.id,
        'requested_role': requestedRole.databaseValue,
        'organisation_name': organisationName,
        'staff_position': staffPosition,
        'reason': reason,
        'proof_path': proofPath,
      });
    } catch (_) {
      await client.storage.from(proofBucket).remove([proofPath]);
      rethrow;
    }
  }

  String _imageExtension(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    if (const {'jpg', 'jpeg', 'png', 'webp'}.contains(extension)) {
      return extension;
    }
    throw ArgumentError('Proof must be a JPG, PNG, or WebP image.');
  }

  String _contentType(String extension) => switch (extension) {
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'webp' => 'image/webp',
    _ => 'application/octet-stream',
  };

  Future<String> createProofUrl(String proofPath) {
    return client.storage
        .from(proofBucket)
        .createSignedUrl(proofPath, const Duration(minutes: 10).inSeconds);
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
