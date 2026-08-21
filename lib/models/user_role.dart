enum UserRole {
  donor,
  admin,
  hospital,
  systemAdmin;

  String get databaseValue => switch (this) {
    UserRole.donor => 'donor',
    UserRole.admin => 'admin',
    UserRole.hospital => 'hospital',
    UserRole.systemAdmin => 'system_admin',
  };

  String get label => switch (this) {
    UserRole.donor => 'Donor',
    UserRole.admin => 'Organisation Admin',
    UserRole.hospital => 'Hospital',
    UserRole.systemAdmin => 'System Admin',
  };

  static UserRole fromDatabase(String? value) => switch (value) {
    'admin' => UserRole.admin,
    'hospital' || 'hospital_admin' => UserRole.hospital,
    'system_admin' => UserRole.systemAdmin,
    _ => UserRole.donor,
  };
}
