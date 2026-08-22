import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../data/remote/official_centre_repository.dart';
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
  final officialRepository = const OfficialCentreRepository();
  final mapController = MapController();
  final addressCache = <String, Future<String>>{};
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
    mapController.dispose();
    super.dispose();
  }

  Future<_CentreData> loadData() async {
    final results = await Future.wait([
      syncService.loadCentres(),
      governmentRepository.loadRecentStats(),
      _loadOfficialCentres(),
    ]);
    final managed = results[0] as List<DonationCentre>;
    final official = results[2] as List<DonationCentre>;
    final byName = <String, DonationCentre>{
      for (final centre in official) centre.name.toLowerCase(): centre,
      for (final centre in managed) centre.name.toLowerCase(): centre,
    };
    return _CentreData(
      byName.values.toList()..sort((a, b) => a.name.compareTo(b.name)),
      results[1] as List<GovernmentDonationStat>,
      official.isNotEmpty,
    );
  }

  Future<List<DonationCentre>> _loadOfficialCentres() async {
    try {
      return await officialRepository.getCentres();
    } on Exception catch (error) {
      debugPrint('Official centre sync failed: $error');
      return const [];
    }
  }

  void showCentre(DonationCentre centre) {
    mapController.move(LatLng(centre.latitude, centre.longitude), 14);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: FutureBuilder<String>(
          future: _addressFor(centre),
          builder: (context, snapshot) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.local_hospital_outlined),
            title: Text(centre.name),
            subtitle: Text(
              snapshot.connectionState != ConnectionState.done
                  ? 'Finding address…\n${centre.state}'
                  : snapshot.hasData
                  ? '${snapshot.data}\n${centre.state}'
                  : 'Address unavailable\n${centre.state}',
            ),
            isThreeLine: true,
          ),
        ),
      ),
    );
  }

  Future<String> _addressFor(DonationCentre centre) {
    if (!centre.id.startsWith('kkm-')) return Future.value(centre.address);
    return addressCache.putIfAbsent(
      centre.id,
      () => officialRepository.getAddress(centre),
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
          final value = snapshot.data ?? const _CentreData([], [], false);
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
                if (!value.officialAvailable) ...[
                  const Card(
                    child: ListTile(
                      leading: Icon(Icons.info_outline),
                      title: Text('Official facility map is unavailable'),
                      subtitle: Text(
                        'Deploy the donation-centres Supabase function, then pull down to retry.',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                TextField(
                  controller: searchController,
                  onChanged: (value) => setState(() => query = value),
                  decoration: const InputDecoration(
                    labelText: 'Search centres by name, address or state',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 16),
                if (centres.isNotEmpty) ...[
                  SizedBox(
                    height: 320,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: FlutterMap(
                        mapController: mapController,
                        options: const MapOptions(
                          initialCenter: LatLng(4.2, 102.0),
                          initialZoom: 5.2,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.mobile_asg',
                          ),
                          MarkerLayer(
                            markers: centres
                                .map(
                                  (centre) => Marker(
                                    point: LatLng(
                                      centre.latitude,
                                      centre.longitude,
                                    ),
                                    width: 46,
                                    height: 46,
                                    child: GestureDetector(
                                      onTap: () => showCentre(centre),
                                      child: Icon(
                                        Icons.location_on,
                                        size: 42,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                          const RichAttributionWidget(
                            attributions: [
                              TextSourceAttribution(
                                'OpenStreetMap contributors',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
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
                        onTap: () => showCentre(centre),
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
  const _CentreData(this.centres, this.stats, this.officialAvailable);

  final List<DonationCentre> centres;
  final List<GovernmentDonationStat> stats;
  final bool officialAvailable;
}
