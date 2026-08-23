class RewardItem {
  const RewardItem({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.pointsCost,
    required this.stockQuantity,
  });

  final String id;
  final String name;
  final String description;
  final String category;
  final int pointsCost;
  final int stockQuantity;

  factory RewardItem.fromMap(Map<String, Object?> map) => RewardItem(
    id: map['id']! as String,
    name: map['name']! as String,
    description: map['description']! as String,
    category: map['category']! as String,
    pointsCost: (map['points_cost']! as num).toInt(),
    stockQuantity: (map['stock_quantity']! as num).toInt(),
  );
}
