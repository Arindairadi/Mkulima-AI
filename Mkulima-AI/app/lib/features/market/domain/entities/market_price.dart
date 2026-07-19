import 'package:equatable/equatable.dart';

class MarketPrice extends Equatable {
  final String cropName;
  final String marketName;
  final double pricePerKgUgx;
  final double changePercent; // vs last week, +ve = up
  final List<double> trend7Day;
  final double? distanceKm; // real, computed from farmer's device location when available
  final bool isNearest;

  const MarketPrice({
    required this.cropName,
    required this.marketName,
    required this.pricePerKgUgx,
    required this.changePercent,
    required this.trend7Day,
    this.distanceKm,
    this.isNearest = false,
  });

  @override
  List<Object?> get props =>
      [cropName, marketName, pricePerKgUgx, changePercent, trend7Day, distanceKm, isNearest];
}
