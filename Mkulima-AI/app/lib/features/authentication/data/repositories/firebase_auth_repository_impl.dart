import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

/// Real Firebase Auth implementation.
///
/// NOT wired in by default (see `auth_provider.dart`, which still uses
/// `MockAuthRepository`) — this requires an actual Firebase project first:
///
///   1. Create a project at https://console.firebase.google.com
///   2. Run `flutterfire configure` from the project root (installs the
///      FlutterFire CLI if needed: `dart pub global activate flutterfire_cli`)
///      This generates `lib/firebase_options.dart` and the native config
///      files (`google-services.json` / `GoogleService-Info.plist`).
///   3. In `main.dart`, before `runApp()`, add:
///        await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
///   4. In `auth_provider.dart`, change:
///        final authRepositoryProvider = Provider<AuthRepository>((ref) => MockAuthRepository());
///      to:
///        final authRepositoryProvider = Provider<AuthRepository>((ref) => FirebaseAuthRepositoryImpl());
///
/// Until all four steps are done, leave `MockAuthRepository` active —
/// this class will throw at runtime if Firebase hasn't been initialized.
class FirebaseAuthRepositoryImpl implements AuthRepository {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;

  UserEntity _mapUser(fb.User user) => UserEntity(
        id: user.uid,
        fullName: user.displayName ?? 'Farmer',
        phoneOrEmail: user.email ?? user.phoneNumber ?? '',
      );

  @override
  Stream<UserEntity?> get authStateChanges =>
      _auth.authStateChanges().map((u) => u == null ? null : _mapUser(u));

  @override
  Future<Either<Failure, UserEntity>> signInWithPhoneOrEmail(
    String identifier,
    String password,
  ) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: identifier,
        password: password,
      );
      if (credential.user == null) {
        return const Left(AuthFailure('Sign-in failed. Please try again.'));
      }
      return Right(_mapUser(credential.user!));
    } on fb.FirebaseAuthException catch (e) {
      return Left(AuthFailure(e.message ?? 'Sign-in failed.'));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> register({
    required String fullName,
    required String identifier,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: identifier,
        password: password,
      );
      await credential.user?.updateDisplayName(fullName);
      await credential.user?.reload();
      final updated = _auth.currentUser;
      if (updated == null) {
        return const Left(AuthFailure('Registration failed. Please try again.'));
      }
      return Right(_mapUser(updated));
    } on fb.FirebaseAuthException catch (e) {
      return Left(AuthFailure(e.message ?? 'Registration failed.'));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();
}
