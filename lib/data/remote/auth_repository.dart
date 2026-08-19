import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/user_role.dart';

class AuthRepository {
  const AuthRepository(this.client);

  final SupabaseClient client;

  Future<bool> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final response = await client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
    if (response.user == null) {
      throw const AuthException('Unable to create the account.');
    }
    return response.session != null;
  }

  Future<UserRole> signIn({
    required String email,
    required String password,
  }) async {
    final response = await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    final user = response.user;
    if (user == null) throw const AuthException('Login failed.');

    final profile = await client
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .single();
    return profile['role'] == UserRole.hospitalAdmin.databaseValue
        ? UserRole.hospitalAdmin
        : UserRole.donor;
  }

  Future<void> signOut() => client.auth.signOut();
}
