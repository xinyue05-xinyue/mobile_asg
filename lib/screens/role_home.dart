import 'package:flutter/material.dart';

import '../app/theme/app_theme.dart';
import '../models/user_role.dart';
import 'admin/admin_dashboard_screen.dart';
import 'admin/qr_attendance_scanner_screen.dart';
import 'donor/donor_shell.dart';
import 'hospital/hospital_dashboard_screen.dart';
import 'hospital/emergency_qr_scanner_screen.dart';
import 'system_admin/system_admin_dashboard_screen.dart';
import 'staff_shell.dart';
import 'staff_profile_screen.dart';
import 'system_admin/system_admin_profile_screen.dart';

Widget homeForRole(UserRole role) => switch (role) {
  UserRole.donor => Theme(
    data: AppTheme.forRole(AppTheme.donor),
    child: const DonorShell(),
  ),
  UserRole.admin => Theme(
    data: AppTheme.forRole(AppTheme.organisation),
    child: const StaffShell(
      mainPage: AdminDashboardScreen(),
      profilePage: StaffProfileScreen(
        roleLabel: 'Organisation',
        useOrganisationColors: true,
      ),
      scannerPage: QrAttendanceScannerScreen(),
    ),
  ),
  UserRole.hospital => Theme(
    data: AppTheme.forRole(AppTheme.hospital),
    child: const StaffShell(
      mainPage: HospitalDashboardScreen(),
      profilePage: StaffProfileScreen(
        roleLabel: 'Hospital',
        useHospitalColors: true,
      ),
      scannerPage: EmergencyQrScannerScreen(),
    ),
  ),
  UserRole.systemAdmin => Theme(
    data: AppTheme.forRole(AppTheme.systemAdmin),
    child: const StaffShell(
      mainPage: SystemAdminDashboardScreen(),
      profilePage: SystemAdminProfileScreen(),
    ),
  ),
};
