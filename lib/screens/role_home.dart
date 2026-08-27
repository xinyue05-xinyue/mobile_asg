import 'package:flutter/material.dart';

import '../models/user_role.dart';
import 'admin/admin_dashboard_screen.dart';
import 'donor/donor_shell.dart';
import 'hospital/hospital_dashboard_screen.dart';
import 'system_admin/system_admin_dashboard_screen.dart';
import 'staff_shell.dart';
import 'staff_profile_screen.dart';
import 'system_admin/system_admin_profile_screen.dart';

Widget homeForRole(UserRole role) => switch (role) {
  UserRole.donor => const DonorShell(),
  UserRole.admin => const StaffShell(
    mainPage: AdminDashboardScreen(),
    profilePage: StaffProfileScreen(roleLabel: 'Organisation'),
  ),
  UserRole.hospital => const StaffShell(
    mainPage: HospitalDashboardScreen(),
    profilePage: StaffProfileScreen(roleLabel: 'Hospital'),
  ),
  UserRole.systemAdmin => const StaffShell(
    mainPage: SystemAdminDashboardScreen(),
    profilePage: SystemAdminProfileScreen(),
  ),
};
