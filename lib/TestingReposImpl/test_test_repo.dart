import 'dart:async';

import 'package:stripes_backend_helper/RepositoryBase/AuthBase/auth_user.dart';
import 'package:stripes_backend_helper/RepositoryBase/SubBase/sub_user.dart';
import 'package:stripes_backend_helper/RepositoryBase/TestBase/BlueDye/blue_dye_impl.dart';
import 'package:stripes_backend_helper/TestingReposImpl/test_question_repo.dart';

import '../RepositoryBase/StampBase/base_stamp_repo.dart';
import '../RepositoryBase/TestBase/BlueDye/blue_dye_response.dart';
import '../RepositoryBase/TestBase/base_test_repo.dart';

final Map<SubUser, BlueDyeTest?> _repo = {};

class TestTestRepo extends TestRepo<BlueDyeTest> {
  final StreamController<BlueDyeTest?> _streamController = StreamController();

  TestTestRepo(StampRepo testResponseRepo, SubUser subUser)
      : super(
            stampRepo: testResponseRepo,
            subUser: subUser,
            authUser: const AuthUser.empty(),
            questionRepo: TestQuestionRepo()) {
    _repo[subUser] = null;
    _streamController.add(null);
  }

  @override
  Future<void> cancel() async {
    _repo[subUser] = null;
    _streamController.add(null);
  }

  @override
  Stream<BlueDyeTest?> get obj => _streamController.stream;

  @override
  Future<void> setValue(BlueDyeTest obj) async {
    _repo[subUser] = obj;
    _streamController.add(_repo[subUser]!);
  }

  @override
  Future<void> submit(DateTime submitTime) async {
    stampRepo.addStamp(BlueDyeResp.from(_repo[subUser]!));
    cancel();
  }
}
