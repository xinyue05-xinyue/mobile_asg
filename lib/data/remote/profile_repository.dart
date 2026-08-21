import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/donation_record.dart';
import '../../models/donor_profile.dart';
import '../../models/profile_overview.dart';
import '../../models/reward_transaction.dart';

class ProfileRepository {
  const ProfileRepository(this.client);

  final SupabaseClient client;

  Future<ProfileOverview> getOverview() async {
    final user = client.auth.currentUser;
    if (user == null) throw const AuthException('Please log in again.');

    final results = await Future.wait([
      client.from('profiles').select().eq('id', user.id).single(),
      client
          .from('donations')
          .select('id, donation_date, verification_status')
          .eq('donor_id', user.id)
          .order('donation_date', ascending: false),
      client
          .from('reward_transactions')
          .select('id, points, transaction_type, created_at')
          .eq('donor_id', user.id)
          .order('created_at', ascending: false),
    ]);

    final profile = DonorProfile.fromMap(results[0] as Map<String, Object?>);
    final donationRows = results[1] as List;
    final rewardRows = results[2] as List;
    final donations = donationRows
        .cast<Map<String, Object?>>()
        .map(DonationRecord.fromMap)
        .toList();
    final rewards = rewardRows
        .cast<Map<String, Object?>>()
        .map(RewardTransaction.fromMap)
        .toList();
    final rewardPoints = rewards.fold<int>(
      0,
      (total, reward) => total + reward.points,
    );

    return ProfileOverview(
      profile: profile,
      donations: donations,
      rewardPoints: rewardPoints,
      rewards: rewards,
    );
  }

  Future<void> updateProfile({
    required String fullName,
    required String? bloodType,
    required String phone,
    required DateTime? dateOfBirth,
    required bool notificationsEnabled,
  }) async {
    final user = client.auth.currentUser;
    if (user == null) throw const AuthException('Please log in again.');
    await client
        .from('profiles')
        .update({
          'full_name': fullName,
          'blood_type': bloodType,
          'phone': phone.isEmpty ? null : phone,
          'date_of_birth': dateOfBirth?.toIso8601String().split('T').first,
          'notifications_enabled': notificationsEnabled,
        })
        .eq('id', user.id);
  }
}
