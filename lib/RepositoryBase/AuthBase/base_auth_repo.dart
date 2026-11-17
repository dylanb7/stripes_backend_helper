import 'auth_user.dart';

abstract class AuthRepo {
  Stream<AuthUser> get user;

  /// Refresh account metadata and publish the confirmed state to [user].
  /// Implementations should throw when the refresh cannot be confirmed.
  Future<void> refresh() async {}

  Future<void> logIn(Map<String, dynamic> params);
  Future<void> signUp(Map<String, dynamic> params);
  Future<bool> resetPassword(String email);
  Future<bool> deleteAccount();
  Future<void> logOut();
}
