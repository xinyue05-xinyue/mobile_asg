class RewardTransaction {
  const RewardTransaction({
    required this.id,
    required this.points,
    required this.transactionType,
    required this.createdAt,
  });

  final String id;
  final int points;
  final String transactionType;
  final DateTime createdAt;

  factory RewardTransaction.fromMap(Map<String, Object?> map) =>
      RewardTransaction(
        id: map['id']! as String,
        points: (map['points']! as num).toInt(),
        transactionType: map['transaction_type']! as String,
        createdAt: DateTime.parse(map['created_at']! as String).toLocal(),
      );
}
