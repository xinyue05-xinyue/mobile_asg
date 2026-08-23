import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/remote/reward_repository.dart';
import '../../data/remote/supabase_service.dart';
import '../../models/reward_item.dart';
import '../../models/reward_redemption.dart';

class RewardStoreScreen extends StatefulWidget {
  const RewardStoreScreen({super.key});

  @override
  State<RewardStoreScreen> createState() => _RewardStoreScreenState();
}

class _RewardStoreScreenState extends State<RewardStoreScreen> {
  late Future<_RewardStoreData> data;
  String? redeemingId;

  RewardRepository? get repository {
    final client = SupabaseService.client;
    return client == null ? null : RewardRepository(client);
  }

  @override
  void initState() {
    super.initState();
    data = loadData();
  }

  Future<_RewardStoreData> loadData() async {
    final repo = repository;
    if (repo == null) return const _RewardStoreData(0, [], []);
    final results = await Future.wait([
      repo.getBalance(),
      repo.getItems(),
      repo.getMine(),
    ]);
    return _RewardStoreData(
      results[0] as int,
      results[1] as List<RewardItem>,
      results[2] as List<RewardRedemption>,
    );
  }

  Future<void> redeem(RewardItem item, int balance) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Redeem reward?'),
        content: Text(
          '${item.name} costs ${item.pointsCost} points. '
          'Your balance after redemption will be ${balance - item.pointsCost} points.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Redeem'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => redeemingId = item.id);
    try {
      final result = await repository!.redeem(item.id);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Reward redeemed'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.redeem, size: 52),
              const SizedBox(height: 12),
              Text(item.name, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              const Text('Redemption code'),
              SelectableText(
                result.code,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text('${result.remainingPoints} points remaining'),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      );
      if (mounted) setState(() => data = loadData());
    } on PostgrestException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => redeemingId = null);
    }
  }

  String dateLabel(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Redeem Rewards')),
      body: FutureBuilder<_RewardStoreData>(
        future: data,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Unable to load rewards: ${snapshot.error}'),
            );
          }
          final value = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async {
              final refreshed = loadData();
              setState(() => data = refreshed);
              await refreshed;
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: ListTile(
                    leading: const Icon(Icons.stars, size: 36),
                    title: Text('${value.balance} available points'),
                    subtitle: const Text(
                      'A verified donation earns 100 points.',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Reward catalogue',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                ...value.items.map((item) {
                  final canAfford = value.balance >= item.pointsCost;
                  final inStock = item.stockQuantity > 0;
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                item.category == 'voucher'
                                    ? Icons.confirmation_number_outlined
                                    : Icons.checkroom_outlined,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  item.name,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ),
                              Text('${item.pointsCost} pts'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(item.description),
                          const SizedBox(height: 8),
                          Text(
                            inStock
                                ? '${item.stockQuantity} available'
                                : 'Out of stock',
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed:
                                  !canAfford || !inStock || redeemingId != null
                                  ? null
                                  : () => redeem(item, value.balance),
                              child: redeemingId == item.id
                                  ? const SizedBox.square(
                                      dimension: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      canAfford
                                          ? 'Redeem'
                                          : 'Not enough points',
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 20),
                Text(
                  'My redemptions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                if (value.redemptions.isEmpty)
                  const Card(
                    child: ListTile(title: Text('No rewards redeemed yet.')),
                  )
                else
                  ...value.redemptions.map(
                    (redemption) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.redeem_outlined),
                        title: Text(redemption.rewardName),
                        subtitle: Text(
                          '${redemption.pointsSpent} points • ${dateLabel(redemption.createdAt)}\n'
                          'Code: ${redemption.code}',
                        ),
                        trailing: Text(redemption.status.toUpperCase()),
                        isThreeLine: true,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RewardStoreData {
  const _RewardStoreData(this.balance, this.items, this.redemptions);

  final int balance;
  final List<RewardItem> items;
  final List<RewardRedemption> redemptions;
}
