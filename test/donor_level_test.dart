import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_asg/models/donor_level.dart';

void main() {
  test('levels use verified donation count at each boundary', () {
    expect(DonorLevel.name(0), 'New donor');
    expect(DonorLevel.name(1), 'Bronze Donor');
    expect(DonorLevel.name(4), 'Bronze Donor');
    expect(DonorLevel.name(5), 'Bronze Donor');
    expect(DonorLevel.name(6), 'Silver Donor');
    expect(DonorLevel.name(15), 'Silver Donor');
    expect(DonorLevel.name(16), 'Gold Donor');
    expect(DonorLevel.nextTarget(16), isNull);
  });
  test('progress measures donations between levels', () {
    expect(DonorLevel.progress(3), 0.4);
    expect(DonorLevel.progress(16), 1);
  });
}
