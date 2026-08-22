import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/organisation_profile.dart';

class SystemAdminRepository {
  const SystemAdminRepository(this.client);

  final SupabaseClient client;

  Future<SystemUserCounts> getUserCounts() async {
    final rows = await client.from('profiles').select('role');
    var donors = 0;
    var admins = 0;
    var hospitals = 0;
    var systemAdmins = 0;
    for (final row in rows) {
      switch (row['role'] as String?) {
        case 'admin':
          admins++;
        case 'hospital' || 'hospital_admin':
          hospitals++;
        case 'system_admin':
          systemAdmins++;
        default:
          donors++;
      }
    }
    return SystemUserCounts(
      donors: donors,
      admins: admins,
      hospitals: hospitals,
      systemAdmins: systemAdmins,
    );
  }

  Future<List<SystemUserSummary>> getUserDirectory() async {
    final rows = await client
        .from('profiles')
        .select('id, full_name, role, blood_type, created_at')
        .order('full_name');
    return rows.map(SystemUserSummary.fromMap).toList();
  }

  Future<void> demoteStaffToDonor(String userId) async {
    await client.rpc('demote_staff_to_donor', params: {'p_user_id': userId});
  }

  Future<SystemUserDetails> getUserDetails(String userId) async {
    final profile = await client
        .from('profiles')
        .select(
          'id, full_name, role, blood_type, phone, date_of_birth, '
          'next_eligible_date, notifications_enabled, created_at',
        )
        .eq('id', userId)
        .single();
    final donationRows = await client
        .from('donations')
        .select('id')
        .eq('donor_id', userId);
    final rewardRows = await client
        .from('reward_transactions')
        .select('points')
        .eq('donor_id', userId);
    final eventRows = await client
        .from('donation_events')
        .select('id')
        .eq('created_by', userId);
    final emergencyRows = await client
        .from('emergency_requests')
        .select('id')
        .eq('hospital_id', userId);
    final organisationRow = await client
        .from('organisation_profiles')
        .select()
        .eq('owner_id', userId)
        .maybeSingle();
    return SystemUserDetails(
      summary: SystemUserSummary.fromMap(profile),
      phone: profile['phone'] as String?,
      dateOfBirth: _date(profile['date_of_birth']),
      nextEligibleDate: _date(profile['next_eligible_date']),
      notificationsEnabled: profile['notifications_enabled'] as bool? ?? true,
      donationCount: donationRows.length,
      rewardPoints: rewardRows.fold<int>(
        0,
        (total, row) => total + ((row as Map)['points'] as num).toInt(),
      ),
      eventCount: eventRows.length,
      emergencyRequestCount: emergencyRows.length,
      organisation: organisationRow == null
          ? null
          : OrganisationProfile.fromMap(organisationRow),
    );
  }

  static DateTime? _date(Object? value) =>
      value == null ? null : DateTime.tryParse(value as String);
}

class SystemUserDetails {
  const SystemUserDetails({
    required this.summary,
    required this.notificationsEnabled,
    required this.donationCount,
    required this.rewardPoints,
    required this.eventCount,
    required this.emergencyRequestCount,
    this.phone,
    this.dateOfBirth,
    this.nextEligibleDate,
    this.organisation,
  });

  final SystemUserSummary summary;
  final String? phone;
  final DateTime? dateOfBirth;
  final DateTime? nextEligibleDate;
  final bool notificationsEnabled;
  final int donationCount;
  final int rewardPoints;
  final int eventCount;
  final int emergencyRequestCount;
  final OrganisationProfile? organisation;
}

class SystemUserSummary {
  const SystemUserSummary({
    required this.id,
    required this.fullName,
    required this.role,
    required this.createdAt,
    this.bloodType,
  });

  final String id;
  final String fullName;
  final String role;
  final String? bloodType;
  final DateTime createdAt;

  factory SystemUserSummary.fromMap(Map<String, Object?> map) =>
      SystemUserSummary(
        id: map['id']! as String,
        fullName: map['full_name']! as String,
        role: map['role']! as String,
        bloodType: map['blood_type'] as String?,
        createdAt: DateTime.parse(map['created_at']! as String).toLocal(),
      );
}

class SystemUserCounts {
  const SystemUserCounts({
    required this.donors,
    required this.admins,
    required this.hospitals,
    required this.systemAdmins,
  });

  final int donors;
  final int admins;
  final int hospitals;
  final int systemAdmins;
}
