import 'dart:async';

import 'package:stripes_backend_helper/RepositoryBase/AuthBase/auth_user.dart';
import 'package:stripes_backend_helper/RepositoryBase/SubBase/sub_user.dart';
import 'package:stripes_backend_helper/RepositoryBase/TestBase/BlueDye/blue_dye_impl.dart';

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
            authUser: const AuthUser.empty()) {
    _repo[subUser] = null;
    _streamController.add(null);
  }

  @override
  cancel() {
    _repo[subUser] = null;
    _streamController.add(null);
  }

  @override
  Stream<BlueDyeTest?> get obj => _streamController.stream;

  @override
  setValue(BlueDyeTest obj) {
    _repo[subUser] = obj;
    print(obj);
    _streamController.add(_repo[subUser]!);
  }

  @override
  submit(DateTime submitTime) {
    stampRepo.addStamp(BlueDyeResp.from(_repo[subUser]!));
    cancel();
  }
}
