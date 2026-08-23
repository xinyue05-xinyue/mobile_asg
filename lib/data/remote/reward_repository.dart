import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/reward_item.dart';
import '../../models/reward_redemption.dart';

class RewardRepository {
  const RewardRepository(this.client);

  final SupabaseClient client;

  Future<List<RewardItem>> getItems() async {
    final rows = await client
        .from('reward_items')
        .select()
        .eq('is_active', true)
        .order('points_cost');
    return rows.map(RewardItem.fromMap).toList();
  }

  Future<List<RewardRedemption>> getMine() async {
    final user = client.auth.currentUser;
    if (user == null) return const [];
    final rows = await client
        .from('reward_redemptions')
        .select(
          'id, points_spent, redemption_code, status, created_at, '
          'reward_item:reward_items(name)',
        )
        .eq('donor_id', user.id)
        .order('created_at', ascending: false);
    return rows.map(RewardRedemption.fromMap).toList();
  }

  Future<int> getBalance() async {
    final user = client.auth.currentUser;
    if (user == null) return 0;
    final rows = await client
        .from('reward_transactions')
        .select('points')
        .eq('donor_id', user.id);
    return rows.fold<int>(
      0,
      (total, row) => total + (row['points'] as num).toInt(),
    );
  }

  Future<({String code, int remainingPoints})> redeem(String itemId) async {
    final rows = await client.rpc(
      'redeem_reward',
      params: {'p_reward_item_id': itemId},
    );
    final row = (rows as List).first as Map<String, Object?>;
    return (
      code: row['redemption_code']! as String,
      remainingPoints: (row['remaining_points']! as num).toInt(),
    );
  }
}
