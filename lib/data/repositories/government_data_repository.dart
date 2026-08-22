import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';

import '../../models/government_donation_stat.dart';
import '../local/app_database.dart';

class GovernmentDataRepository {
  GovernmentDataRepository({AppDatabase? appDatabase, http.Client? client})
    : _appDatabase = appDatabase ?? AppDatabase.instance,
      _client = client ?? http.Client();

  final AppDatabase _appDatabase;
  final http.Client _client;

  Future<List<GovernmentDonationStat>> loadRecentStats() async {
    try {
      final remote = await _fetchRemote();
      if (!kIsWeb) await _replaceCache(remote);
      return remote;
    } on Exception catch (error) {
      debugPrint('Government data sync failed; using cache: $error');
      if (kIsWeb) return const [];
      return _getCached();
    }
  }

  Future<List<GovernmentDonationStat>> _fetchRemote() async {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month);
    final start = startDate.toIso8601String().split('T').first;
    final uri = Uri.https('api.data.gov.my', '/data-catalogue', {
      'id': 'blood_donations',
      'limit': '200',
      'date_start': '$start@date',
    });
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw http.ClientException(
        'data.gov.my returned ${response.statusCode}',
        uri,
      );
    }
    final decoded = jsonDecode(response.body) as List;
    return decoded
        .cast<Map<String, Object?>>()
        .map(GovernmentDonationStat.fromMap)
        .toList();
  }

  Future<void> _replaceCache(Iterable<GovernmentDonationStat> stats) async {
    final database = await _appDatabase.database;
    final syncedAt = DateTime.now().toUtc().toIso8601String();
    await database.transaction((transaction) async {
      await transaction.delete('government_donation_stats');
      for (final stat in stats) {
        await transaction.insert(
          'government_donation_stats',
          {...stat.toMap(), 'synced_at': syncedAt},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<List<GovernmentDonationStat>> _getCached() async {
    final database = await _appDatabase.database;
    final rows = await database.query(
      'government_donation_stats',
      orderBy: 'date DESC, state, blood_type',
    );
    return rows.map(GovernmentDonationStat.fromMap).toList();
  }
}
