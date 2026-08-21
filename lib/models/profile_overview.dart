import 'donation_record.dart';
import 'donor_profile.dart';
import 'reward_transaction.dart';

class ProfileOverview {
  const ProfileOverview({
    required this.profile,
    required this.donations,
    required this.rewardPoints,
    required this.rewards,
  });

  final DonorProfile profile;
  final List<DonationRecord> donations;
  final int rewardPoints;
  final List<RewardTransaction> rewards;
}
