import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> signInWithPhoneOrEmail(String identifier, String password);
  Future<Either<Failure, UserEntity>> register({
    required String fullName,
    required String identifier,
    required String password,
  });
  Future<void> signOut();
  Stream<UserEntity?> get authStateChanges;
}
