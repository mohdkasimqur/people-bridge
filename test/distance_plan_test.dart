import 'package:flutter_test/flutter_test.dart';
import 'package:jober_india/jober_indiaScreens.dart/distance_plan.dart';

DistancePlan _plan(double price, int offerPercent) => DistancePlan(
      distance: 5,
      duration: '1 day',
      durationHours: 24,
      originalPrice: price,
      offerPercent: offerPercent,
    );

void main() {
  test('DistancePlan.finalPrice applies the offer percentage', () {
    expect(_plan(200, 25).finalPrice, 150);
    expect(_plan(99, 100).finalPrice, 0);
  });

  test('DistancePlan.finalPrice ignores a zero or negative offer', () {
    expect(_plan(200, 0).finalPrice, 200);
    expect(_plan(200, -10).finalPrice, 200);
  });
}
