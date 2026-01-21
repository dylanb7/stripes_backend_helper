import 'dart:async';

import 'package:stripes_backend_helper/RepositoryBase/AuthBase/auth_user.dart';
import 'package:stripes_backend_helper/RepositoryBase/repo_result.dart';

import '../RepositoryBase/SubBase/base_sub_repo.dart';
import '../RepositoryBase/SubBase/sub_user.dart';

class TestSubRepo extends SubUserRepo {
  List<SubUser> subUsers = [];

  StreamController<List<SubUser>> curr = StreamController();

  TestSubRepo(AuthUser user) : super(authUser: user);
  @override
  Future<RepoResult<SubUser?>> addSubUser(SubUser user) async {
    subUsers.add(user);
    curr.add(subUsers);
    return Success(user);
  }

  @override
  Future<RepoResult<void>> deleteSubUser(SubUser user) async {
    subUsers.removeWhere((element) => element.uid == user.uid);
    curr.add(subUsers);
    return const Success(null);
  }

  @override
  Future<RepoResult<SubUser?>> updateSubUser(SubUser user) async {
    subUsers[subUsers.indexWhere((element) => element.uid == user.uid)] = user;
    curr.add(subUsers);
    return Success(user);
  }

  @override
  Stream<List<SubUser>> get users => curr.stream;

  @override
  Future<void> refresh() async {}
}
