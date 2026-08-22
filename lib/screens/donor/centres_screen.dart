import 'package:flutter/material.dart';

import '../../data/repositories/data_sync_service.dart';
import '../../data/repositories/government_data_repository.dart';
import '../../models/donation_centre.dart';
import '../../models/government_donation_stat.dart';

class CentresScreen extends StatefulWidget {
  const CentresScreen({super.key});

  @override
  State<CentresScreen> createState() => _CentresScreenState();
}

class _CentresScreenState extends State<CentresScreen> {
  final searchController = TextEditingController();
  final syncService = DataSyncService();
  final governmentRepository = GovernmentDataRepository();
  late Future<_CentreData> data;
  String query = '';

  @override
  void initState() {
    super.initState();
    data = loadData();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<_CentreData> loadData() async {
    final results = await Future.wait([
      syncService.loadCentres(),
      governmentRepository.loadRecentStats(),
    ]);
    return _CentreData(
      results[0] as List<DonationCentre>,
      results[1] as List<GovernmentDonationStat>,
    );
  }

  List<DonationCentre> filteredCentres(List<DonationCentre> centres) {
    final search = query.trim().toLowerCase();
    if (search.isEmpty) return centres;
    return centres.where((centre) {
      return centre.name.toLowerCase().contains(search) ||
          centre.address.toLowerCase().contains(search) ||
          centre.state.toLowerCase().contains(search);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Donation Centres')),
      body: FutureBuilder<_CentreData>(
        future: data,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Unable to load data: ${snapshot.error}'),
            );
          }
          final value = snapshot.data ?? const _CentreData([], []);
          final centres = filteredCentres(value.centres);
          return RefreshIndicator(
            onRefresh: () async => setState(() {
              data = loadData();
            }),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _GovernmentActivityCard(stats: value.stats),
                const SizedBox(height: 16),
                TextField(
                  controller: searchController,
                  onChanged: (value) => setState(() => query = value),
                  decoration: const InputDecoration(
                    labelText: 'Search centres by name, address or state',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 16),
                if (centres.isEmpty)
                  const Card(
                    child: ListTile(
                      title: Text('No matching donation centres.'),
                      subtitle: Text(
                        'Centre records can be added by an organisation admin.',
                      ),
                    ),
                  )
                else
                  ...centres.map(
                    (centre) => Card(
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
                          '${centre.address}\n${centre.state}'
                          '${centre.operatingHours == null ? '' : '\n${centre.operatingHours}'}',
                        ),
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

class _GovernmentActivityCard extends StatelessWidget {
  const _GovernmentActivityCard({required this.stats});

  final List<GovernmentDonationStat> stats;

  String dateLabel(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.cloud_off_outlined),
          title: Text('Government donation activity unavailable'),
          subtitle: Text('Connect to the internet to retrieve official data.'),
        ),
      );
    }

    final latestDate = stats
        .map((stat) => stat.date)
        .reduce((first, second) => first.isAfter(second) ? first : second);
    final latest = stats
        .where(
          (stat) =>
              stat.date.year == latestDate.year &&
              stat.date.month == latestDate.month &&
              stat.date.day == latestDate.day,
        )
        .toList();
    final total = latest
        .where((stat) => stat.bloodType == 'all')
        .fold<int>(0, (sum, stat) => sum + stat.donations);
    final groupTotals = <String, int>{};
    for (final stat in latest.where((stat) => stat.bloodType != 'all')) {
      groupTotals.update(
        stat.bloodType,
        (value) => value + stat.donations,
        ifAbsent: () => stat.donations,
      );
    }
    final groups = groupTotals.entries
        .map((entry) => '${entry.key.toUpperCase()}: ${entry.value}')
        .join('  •  ');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.public,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Malaysia blood donation activity',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '$total donations',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text('Data date: ${dateLabel(latestDate)}'),
            if (groups.isNotEmpty) ...[const SizedBox(height: 8), Text(groups)],
            const SizedBox(height: 12),
            const Text(
              'Source: National Blood Centre and Ministry of Health Malaysia via data.gov.my. The dataset covers 22 main BBISv2 collection sites.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _CentreData {
  const _CentreData(this.centres, this.stats);

  final List<DonationCentre> centres;
  final List<GovernmentDonationStat> stats;
}
