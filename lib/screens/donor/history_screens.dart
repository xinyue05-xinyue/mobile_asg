import 'package:flutter/material.dart';

import '../../models/donation_record.dart';
import '../../models/reward_transaction.dart';

String _dateLabel(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}

class DonationHistoryScreen extends StatelessWidget {
  const DonationHistoryScreen({super.key, required this.donations});

  final List<DonationRecord> donations;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Donation history')),
      body: donations.isEmpty
          ? const Center(child: Text('No donation records yet.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: donations.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final donation = donations[index];
                final emergency = donation.emergencyRequestId != null;
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      child: Icon(
                        emergency
                            ? Icons.emergency_outlined
                            : Icons.bloodtype_outlined,
                      ),
                    ),
                    title: Text(donation.sourceLabel),
                    subtitle: Text(
                      '${_dateLabel(donation.donationDate)}\n'
                      'Status: ${donation.verificationStatus}',
                    ),
                    isThreeLine: true,
                    trailing: const Icon(Icons.verified, color: Colors.green),
                  ),
                );
              },
            ),
    );
  }
}

class RewardHistoryScreen extends StatelessWidget {
  const RewardHistoryScreen({super.key, required this.rewards});

  final List<RewardTransaction> rewards;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reward history')),
      body: rewards.isEmpty
          ? const Center(child: Text('No reward transactions yet.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: rewards.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final reward = rewards[index];
                final earned = reward.points >= 0;
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      child: Icon(earned ? Icons.add : Icons.redeem_outlined),
                    ),
                    title: Text(
                      '${reward.points > 0 ? '+' : ''}${reward.points} points',
                    ),
                    subtitle: Text(
                      '${earned ? 'Points earned' : 'Reward redeemed'}\n'
                      '${_dateLabel(reward.createdAt)}',
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }
}
