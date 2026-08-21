import 'package:flutter/material.dart';

import '../models/user_role.dart';
import 'admin/admin_dashboard_screen.dart';
import 'donor/donor_shell.dart';
import 'hospital/hospital_dashboard_screen.dart';
import 'system_admin/system_admin_dashboard_screen.dart';

Widget homeForRole(UserRole role) => switch (role) {
  UserRole.donor => const DonorShell(),
  UserRole.admin => const AdminDashboardScreen(),
  UserRole.hospital => const HospitalDashboardScreen(),
  UserRole.systemAdmin => const SystemAdminDashboardScreen(),
};
