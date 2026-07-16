import 'package:equatable/equatable.dart';

class FarmRecord extends Equatable {
  final String id;
  final String name;
  final String cropName;
  final double sizeAcres;
  final DateTime plantingDate;
  final double totalExpensesUgx;
  final double totalIncomeUgx;

  const FarmRecord({
    required this.id,
    required this.name,
    required this.cropName,
    required this.sizeAcres,
    required this.plantingDate,
    this.totalExpensesUgx = 0,
    this.totalIncomeUgx = 0,
  });

  double get profitUgx => totalIncomeUgx - totalExpensesUgx;

  FarmRecord copyWith({
    String? name,
    String? cropName,
    double? sizeAcres,
    DateTime? plantingDate,
    double? totalExpensesUgx,
    double? totalIncomeUgx,
  }) {
    return FarmRecord(
      id: id,
      name: name ?? this.name,
      cropName: cropName ?? this.cropName,
      sizeAcres: sizeAcres ?? this.sizeAcres,
      plantingDate: plantingDate ?? this.plantingDate,
      totalExpensesUgx: totalExpensesUgx ?? this.totalExpensesUgx,
      totalIncomeUgx: totalIncomeUgx ?? this.totalIncomeUgx,
    );
  }

  @override
  List<Object?> get props =>
      [id, name, cropName, sizeAcres, plantingDate, totalExpensesUgx, totalIncomeUgx];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'cropName': cropName,
        'sizeAcres': sizeAcres,
        'plantingDate': plantingDate.toIso8601String(),
        'totalExpensesUgx': totalExpensesUgx,
        'totalIncomeUgx': totalIncomeUgx,
      };

  factory FarmRecord.fromJson(Map<String, dynamic> json) => FarmRecord(
        id: json['id'] as String,
        name: json['name'] as String,
        cropName: json['cropName'] as String,
        sizeAcres: (json['sizeAcres'] as num).toDouble(),
        plantingDate: DateTime.parse(json['plantingDate'] as String),
        totalExpensesUgx: (json['totalExpensesUgx'] as num).toDouble(),
        totalIncomeUgx: (json['totalIncomeUgx'] as num).toDouble(),
      );
}
