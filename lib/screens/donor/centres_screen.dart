import 'package:flutter/material.dart';

import '../../data/repositories/data_sync_service.dart';
import '../../models/donation_centre.dart';

class CentresScreen extends StatefulWidget {
  const CentresScreen({super.key});

  @override
  State<CentresScreen> createState() => _CentresScreenState();
}

class _CentresScreenState extends State<CentresScreen> {
  final syncService = DataSyncService();
  late Future<List<DonationCentre>> centres;

  @override
  void initState() {
    super.initState();
    centres = syncService.loadCentres();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Donation Centres')),
      body: FutureBuilder<List<DonationCentre>>(
        future: centres,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Unable to load cached centres.'));
          }

          final items = snapshot.data ?? const [];
          if (items.isEmpty) {
            return const Center(child: Text('No cached donation centres.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final centre = items[index];
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    child: const Icon(Icons.local_hospital_outlined),
                  ),
                  title: Text(centre.name),
                  subtitle: Text(
                    '${centre.address}\n${centre.operatingHours ?? ''}',
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
