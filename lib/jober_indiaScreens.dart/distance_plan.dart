// import 'package:flutter/material.dart';
// import 'package:hive/hive.dart';
// your other imports


// ==========================================================
// DISTANCE PLAN
// ==========================================================

class DistancePlan {
  final double distance;
  final String duration;
  final int durationHours;
  final double originalPrice;
  final int offerPercent;

  const DistancePlan({
    required this.distance,
    required this.duration,
    required this.durationHours,
    required this.originalPrice,
    required this.offerPercent,
  });

  double get finalPrice {
    if (offerPercent <= 0) {
      return originalPrice;
    }

    return originalPrice -
        (originalPrice * offerPercent / 100);
  }
}