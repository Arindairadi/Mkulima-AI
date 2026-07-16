import 'package:equatable/equatable.dart';

class DiseaseResult extends Equatable {
  final String cropName;
  final String diseaseName;
  final double confidence; // 0.0 - 1.0
  final String cause;
  final List<String> treatments;
  final List<String> preventionTips;
  final bool isHealthy;

  const DiseaseResult({
    required this.cropName,
    required this.diseaseName,
    required this.confidence,
    required this.cause,
    required this.treatments,
    required this.preventionTips,
    this.isHealthy = false,
  });

  @override
  List<Object?> get props =>
      [cropName, diseaseName, confidence, cause, treatments, preventionTips, isHealthy];
}
