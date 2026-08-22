import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';

import '../../models/government_donation_stat.dart';
import '../local/app_database.dart';
import '../local/platform_support.dart';

class GovernmentDataRepository {
  GovernmentDataRepository({AppDatabase? appDatabase, http.Client? client})
    : _appDatabase = appDatabase ?? AppDatabase.instance,
      _client = client ?? http.Client();

  final AppDatabase _appDatabase;
  final http.Client _client;

  Future<List<GovernmentDonationStat>> loadRecentStats() async {
    return loadStatsForMonth(DateTime.now());
  }

  Future<List<GovernmentDonationStat>> loadStatsForMonth(DateTime month) async {
    try {
      final remote = await _fetchRemote(month);
      if (supportsMobileSqlite) await _replaceCache(month, remote);
      return remote;
    } on Exception catch (error) {
      debugPrint('Government data sync failed; using cache: $error');
      if (!supportsMobileSqlite) return const [];
      return _getCached(month);
    }
  }

  Future<List<GovernmentDonationStat>> _fetchRemote(DateTime month) async {
    final startDate = DateTime(month.year, month.month);
    final nextMonth = DateTime(month.year, month.month + 1);
    final endDate = nextMonth.subtract(const Duration(days: 1));
    final start = startDate.toIso8601String().split('T').first;
    final end = endDate.toIso8601String().split('T').first;
    final uri = Uri.https('api.data.gov.my', '/data-catalogue', {
      'id': 'blood_donations',
      'limit': '200',
      'date_start': '$start@date',
      'date_end': '$end@date',
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

  Future<void> _replaceCache(
    DateTime month,
    Iterable<GovernmentDonationStat> stats,
  ) async {
    final database = await _appDatabase.database;
    final syncedAt = DateTime.now().toUtc().toIso8601String();
    await database.transaction((transaction) async {
      final start = DateTime(
        month.year,
        month.month,
      ).toIso8601String().split('T').first;
      final next = DateTime(
        month.year,
        month.month + 1,
      ).toIso8601String().split('T').first;
      await transaction.delete(
        'government_donation_stats',
        where: 'date >= ? AND date < ?',
        whereArgs: [start, next],
      );
      for (final stat in stats) {
        await transaction.insert(
          'government_donation_stats',
          {...stat.toMap(), 'synced_at': syncedAt},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<List<GovernmentDonationStat>> _getCached(DateTime month) async {
    final database = await _appDatabase.database;
    final start = DateTime(
      month.year,
      month.month,
    ).toIso8601String().split('T').first;
    final next = DateTime(
      month.year,
      month.month + 1,
    ).toIso8601String().split('T').first;
    final rows = await database.query(
      'government_donation_stats',
      where: 'date >= ? AND date < ?',
      whereArgs: [start, next],
      orderBy: 'date DESC, state, blood_type',
    );
    return rows.map(GovernmentDonationStat.fromMap).toList();
  }
}
