import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/about_us_content.dart';

class AboutUsRepository {
  const AboutUsRepository(this.client);

  final SupabaseClient client;

  static const fallback = AboutUsContent(
    title: 'About MyDarah',
    content:
        'MyDarah connects donors, blood-donation organisations, and hospitals '
        'in one place. The app helps donors discover donation opportunities, '
        'respond to emergency blood requests, track verified donations, and '
        'receive rewards for their contribution.\n\n'
        'Our goal is to make blood donation more accessible, organised, and '
        'timely for the community.',
  );

  Future<AboutUsContent> getContent() async {
    final rows = await client.from('about_us').select().eq('id', 1).limit(1);
    if (rows.isEmpty) return fallback;
    return AboutUsContent.fromMap(rows.first);
  }

  Future<void> update({required String title, required String content}) async {
    final trimmedTitle = title.trim();
    final trimmedContent = content.trim();
    if (trimmedTitle.isEmpty || trimmedContent.isEmpty) {
      throw ArgumentError('The title and content are required.');
    }
    await client
        .from('about_us')
        .update({
          'title': trimmedTitle,
          'content': trimmedContent,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', 1);
  }
}
