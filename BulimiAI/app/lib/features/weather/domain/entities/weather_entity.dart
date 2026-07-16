import 'package:equatable/equatable.dart';

enum WeatherAlertLevel { none, drought, flood }

class DailyForecast extends Equatable {
  final DateTime date;
  final double tempHighC;
  final double tempLowC;
  final int rainChancePercent;
  final String condition; // e.g. "Light rain", "Sunny"

  const DailyForecast({
    required this.date,
    required this.tempHighC,
    required this.tempLowC,
    required this.rainChancePercent,
    required this.condition,
  });

  @override
  List<Object?> get props => [date, tempHighC, tempLowC, rainChancePercent, condition];
}

class WeatherSnapshot extends Equatable {
  final String village;
  final double currentTempC;
  final int humidityPercent;
  final double windKph;
  final WeatherAlertLevel alertLevel;
  final String aiRecommendation;
  final List<DailyForecast> forecast;

  const WeatherSnapshot({
    required this.village,
    required this.currentTempC,
    required this.humidityPercent,
    required this.windKph,
    required this.alertLevel,
    required this.aiRecommendation,
    required this.forecast,
  });

  @override
  List<Object?> get props =>
      [village, currentTempC, humidityPercent, windKph, alertLevel, aiRecommendation, forecast];
}
