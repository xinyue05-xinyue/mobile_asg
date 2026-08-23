import 'package:flutter/material.dart';

import '../data/remote/official_centre_repository.dart';

class LocationSuggestions extends StatelessWidget {
  const LocationSuggestions({
    super.key,
    required this.results,
    required this.onSelected,
  });

  final List<LocationSearchResult> results;
  final ValueChanged<LocationSearchResult> onSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 6,
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 280),
        child: ListView.separated(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          itemCount: results.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final result = results[index];
            return ListTile(
              leading: const Icon(Icons.place_outlined),
              title: Text(result.address),
              onTap: () => onSelected(result),
            );
          },
        ),
      ),
    );
  }
}
