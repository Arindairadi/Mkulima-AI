import 'dart:async';
import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

/// In-memory mock implementation of [AuthRepository].
///
/// This lets the whole app (dashboard, farm management, etc.) run and be
/// demoed end-to-end without a configured Firebase project. Swap this for
/// a `FirebaseAuthRepositoryImpl` (using `firebase_auth`, already in
/// pubspec.yaml) once `google-services.json` / `GoogleService-Info.plist`
/// are added and `Firebase.initializeApp()` is called in `main.dart` — the
/// domain layer (use cases, providers) will not need to change since they
/// only depend on the `AuthRepository` interface.
class MockAuthRepository implements AuthRepository {
  final _controller = StreamController<UserEntity?>.broadcast();
  UserEntity? _current;

  @override
  Stream<UserEntity?> get authStateChanges => _controller.stream;

  @override
  Future<Either<Failure, UserEntity>> signInWithPhoneOrEmail(
    String identifier,
    String password,
  ) async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (identifier.trim().isEmpty || password.length < 4) {
      return const Left(ValidationFailure('Enter a valid phone/email and a password of at least 4 characters.'));
    }
    final user = UserEntity(id: 'u_${identifier.hashCode}', fullName: 'Farmer', phoneOrEmail: identifier);
    _current = user;
    _controller.add(user);
    return Right(user);
  }

  @override
  Future<Either<Failure, UserEntity>> register({
    required String fullName,
    required String identifier,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (fullName.trim().isEmpty) {
      return const Left(ValidationFailure('Please enter your full name.'));
    }
    final user = UserEntity(id: 'u_${identifier.hashCode}', fullName: fullName, phoneOrEmail: identifier);
    _current = user;
    _controller.add(user);
    return Right(user);
  }

  @override
  Future<void> signOut() async {
    _current = null;
    _controller.add(null);
  }
}
