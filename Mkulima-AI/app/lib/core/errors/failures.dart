import 'package:equatable/equatable.dart';

/// Base class for all domain-layer failures.
///
/// Repositories return `Either<Failure, T>` (via `dartz`) instead of
/// throwing, so use-cases and UI code can pattern-match on failure type
/// and show the right message/action to a farmer with low connectivity
/// or a low-end device, rather than crashing on an unhandled exception.
abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Something went wrong on our servers. Please try again.']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection. Showing saved data where available.']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'No saved data found on this device.']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'We could not verify your account. Please log in again.']);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// Used by the disease-detection / voice-assistant modules when an AI
/// model call fails or returns a low-confidence/garbage result.
class AiInferenceFailure extends Failure {
  const AiInferenceFailure([super.message = 'The AI assistant could not process this right now.']);
}

class LocationFailure extends Failure {
  const LocationFailure([super.message = 'Could not determine your farm location.']);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Something unexpected happened.']);
}
