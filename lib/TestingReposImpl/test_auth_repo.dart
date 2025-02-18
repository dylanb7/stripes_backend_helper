// ignore_for_file: avoid_print

import 'dart:async';

import '../RepositoryBase/AuthBase/auth_user.dart';
import '../RepositoryBase/AuthBase/base_auth_repo.dart';

class TestAuth extends AuthRepo {
  AuthUser _user = const AuthUser.empty();

  final StreamController<AuthUser> _authUser = StreamController();
  @override
  Future<void> logIn(Map<String, dynamic> params) async {
    print('Logged in');
    _user = const AuthUser(uid: 'uid', attributes: {});
    _authUser.add(_user);
  }

  @override
  Future<void> logOut() async {
    _user = const AuthUser.empty();
    _authUser.add(_user);
  }

  @override
  Future<bool> resetPassword(String email) {
    throw UnimplementedError();
  }

  @override
  Future<void> signUp(Map<String, dynamic> params) async {
    print('Signed up');
    _user = const AuthUser.uid(uid: 'uid');
    _authUser.add(_user);
  }

  @override
  Stream<AuthUser> get user => _authUser.stream;

  @override
  Future<bool> deleteAccount() async {
    return false;
  }
}
