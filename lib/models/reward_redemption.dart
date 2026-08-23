class RewardRedemption {
  const RewardRedemption({
    required this.id,
    required this.rewardName,
    required this.pointsSpent,
    required this.code,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String rewardName;
  final int pointsSpent;
  final String code;
  final String status;
  final DateTime createdAt;

  factory RewardRedemption.fromMap(Map<String, Object?> map) {
    final item = map['reward_item'] as Map<String, Object?>?;
    return RewardRedemption(
      id: map['id']! as String,
      rewardName: item?['name'] as String? ?? 'Reward',
      pointsSpent: (map['points_spent']! as num).toInt(),
      code: map['redemption_code']! as String,
      status: map['status']! as String,
      createdAt: DateTime.parse(map['created_at']! as String).toLocal(),
    );
  }
}
