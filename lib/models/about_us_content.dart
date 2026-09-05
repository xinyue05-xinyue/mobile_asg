class AboutUsContent {
  const AboutUsContent({
    required this.title,
    required this.content,
    this.updatedAt,
  });

  final String title;
  final String content;
  final DateTime? updatedAt;

  factory AboutUsContent.fromMap(Map<String, Object?> map) => AboutUsContent(
    title: map['title'] as String? ?? 'About MyDarah',
    content: map['content'] as String? ?? '',
    updatedAt: map['updated_at'] == null
        ? null
        : DateTime.tryParse(map['updated_at']! as String)?.toLocal(),
  );
}
