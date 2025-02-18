import 'auth_user.dart';

abstract class AuthRepo {
  Stream<AuthUser> get user;
  Future<void> logIn(Map<String, dynamic> params);
  Future<void> signUp(Map<String, dynamic> params);
  Future<bool> resetPassword(String email);
  Future<bool> deleteAccount();
  Future<void> logOut();
}
