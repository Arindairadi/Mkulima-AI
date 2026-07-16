/// Exceptions thrown at the data-source layer (remote/local).
///
/// Repositories catch these and translate them into [Failure]s so the
/// domain/presentation layers never depend on Dio, Isar, or any other
/// concrete package.
class ServerException implements Exception {
  final String message;
  final int? statusCode;
  const ServerException([this.message = 'Server error', this.statusCode]);
}

class CacheException implements Exception {
  final String message;
  const CacheException([this.message = 'Cache error']);
}

class NetworkException implements Exception {
  final String message;
  const NetworkException([this.message = 'No network connection']);
}

class AuthException implements Exception {
  final String message;
  const AuthException([this.message = 'Authentication error']);
}
