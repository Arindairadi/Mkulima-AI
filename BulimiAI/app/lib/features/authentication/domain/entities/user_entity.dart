import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String fullName;
  final String phoneOrEmail;
  final String? district; // e.g. "Kiryandongo" — used to scope weather/market data
  final String preferredLanguageCode; // matches AppConstants.supportedLanguages

  const UserEntity({
    required this.id,
    required this.fullName,
    required this.phoneOrEmail,
    this.district,
    this.preferredLanguageCode = 'en-UG',
  });

  @override
  List<Object?> get props => [id, fullName, phoneOrEmail, district, preferredLanguageCode];
}
