enum UserRole {
  donor,
  hospitalAdmin;

  String get databaseValue => switch (this) {
    UserRole.donor => 'donor',
    UserRole.hospitalAdmin => 'hospital_admin',
  };
}
