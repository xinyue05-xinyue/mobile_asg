class DonorLevel {
  const DonorLevel._();

  static String name(int donationCount, {bool short = false}) {
    final level = donationCount >= 10
        ? 'Gold'
        : donationCount >= 5
        ? 'Silver'
        : donationCount >= 1
        ? 'Bronze'
        : 'New donor';
    return short || level == 'New donor' ? level : '$level Donor';
  }

  static int? nextTarget(int donationCount) {
    if (donationCount < 1) return 1;
    if (donationCount < 5) return 5;
    if (donationCount < 10) return 10;
    return null;
  }

  static double progress(int donationCount) {
    final target = nextTarget(donationCount);
    if (target == null) return 1;
    final previousTarget = donationCount < 1
        ? 0
        : donationCount < 5
        ? 1
        : 5;
    return ((donationCount - previousTarget) / (target - previousTarget)).clamp(
      0,
      1,
    );
  }
}
