import 'package:flutter/material.dart';

import '../data/repositories/government_data_repository.dart';
import '../models/government_donation_stat.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final repository = GovernmentDataRepository();
  late Future<List<GovernmentDonationStat>> stats;

  @override
  void initState() {
    super.initState();
    stats = repository.loadRecentStats();
  }

  Future<void> refresh() async {
    final refreshed = repository.loadRecentStats();
    setState(() => stats = refreshed);
    await refreshed;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Donation Statistics')),
      body: FutureBuilder<List<GovernmentDonationStat>>(
        future: stats,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _StatisticsMessage(
              icon: Icons.cloud_off_outlined,
              title: 'Unable to load official statistics',
              message: '${snapshot.error}',
              onRetry: refresh,
            );
          }
          final values = snapshot.data ?? const [];
          if (values.isEmpty) {
            return _StatisticsMessage(
              icon: Icons.bar_chart_outlined,
              title: 'No statistics available',
              message:
                  'The government API returned no records for this month. Tap retry later.',
              onRetry: refresh,
            );
          }
          return _MonthlyOverview(stats: values, onRefresh: refresh);
        },
      ),
    );
  }
}

class StatisticsIconButton extends StatelessWidget {
  const StatisticsIconButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Donation statistics',
      icon: const Icon(Icons.bar_chart_outlined),
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const StatisticsScreen()),
      ),
    );
  }
}

class _MonthlyOverview extends StatelessWidget {
  const _MonthlyOverview({required this.stats, required this.onRefresh});

  final List<GovernmentDonationStat> stats;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final dayGroups = <DateTime, List<GovernmentDonationStat>>{};
    for (final stat in stats) {
      final day = DateTime(stat.date.year, stat.date.month, stat.date.day);
      dayGroups.putIfAbsent(day, () => []).add(stat);
    }
    final dayTotals =
        dayGroups.entries
            .map((entry) => MapEntry(entry.key, _totalFor(entry.value)))
            .toList()
          ..sort((a, b) => a.key.compareTo(b.key));
    final monthlyTotal = dayTotals.fold<int>(0, (sum, row) => sum + row.value);
    final maximum = dayTotals.fold<int>(
      0,
      (value, row) => row.value > value ? row.value : value,
    );
    final latestDate = dayTotals.last.key;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.public),
              title: Text('$monthlyTotal donations this month'),
              subtitle: Text(
                '${_monthLabel(latestDate)} • Latest data: ${_dateLabel(latestDate)}',
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Daily donations in ${_monthLabel(latestDate)}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          const Text('Tap a day to view its blood-group breakdown.'),
          const SizedBox(height: 12),
          ...dayTotals.map(
            (row) => _BarRow(
              label: _shortDateLabel(row.key),
              value: row.value,
              maximum: maximum,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => _DayDetailScreen(
                    date: row.key,
                    stats: dayGroups[row.key]!,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Source: Pusat Darah Negara and Ministry of Health Malaysia via data.gov.my (blood_donations).',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _DayDetailScreen extends StatelessWidget {
  const _DayDetailScreen({required this.date, required this.stats});

  final DateTime date;
  final List<GovernmentDonationStat> stats;

  @override
  Widget build(BuildContext context) {
    const bloodTypes = ['a', 'b', 'ab', 'o'];
    final values = {
      for (final type in bloodTypes)
        type: stats
            .where((stat) => stat.bloodType.toLowerCase() == type)
            .fold<int>(0, (sum, stat) => sum + stat.donations),
    };
    final total = _totalFor(stats);
    final maximum = values.values.fold<int>(0, (a, b) => b > a ? b : a);

    return Scaffold(
      appBar: AppBar(title: Text(_dateLabel(date))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.bloodtype_outlined),
              title: Text('$total donations'),
              subtitle: Text('Data date: ${_dateLabel(date)}'),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Blood-group breakdown',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          ...bloodTypes.map(
            (type) => _BarRow(
              label: type.toUpperCase(),
              value: values[type]!,
              maximum: maximum,
            ),
          ),
        ],
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  const _BarRow({
    required this.label,
    required this.value,
    required this.maximum,
    this.onTap,
  });

  final String label;
  final int value;
  final int maximum;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fraction = maximum == 0 ? 0.0 : value / maximum;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(label)),
                  Text(
                    '$value',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (onTap != null) const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: fraction,
                  minHeight: 14,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatisticsMessage extends StatelessWidget {
  const _StatisticsMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final IconData icon;
  final String title;
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

int _totalFor(Iterable<GovernmentDonationStat> stats) {
  final all = stats
      .where((stat) => stat.bloodType.toLowerCase() == 'all')
      .fold<int>(0, (sum, stat) => sum + stat.donations);
  if (all > 0) return all;
  return stats
      .where((stat) => stat.bloodType.toLowerCase() != 'all')
      .fold<int>(0, (sum, stat) => sum + stat.donations);
}

String _dateLabel(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}

String _shortDateLabel(DateTime value) =>
    '${value.day} ${_monthName(value.month)}';

String _monthLabel(DateTime value) =>
    '${_monthName(value.month)} ${value.year}';

String _monthName(int month) => const [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
][month - 1];
