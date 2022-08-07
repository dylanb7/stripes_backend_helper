import 'package:stripes_backend_helper/RepositoryBase/StampBase/base_stamp_repo.dart';
import 'package:stripes_backend_helper/RepositoryBase/SubBase/sub_user.dart';

import '../AuthBase/auth_user.dart';
import 'test_obj.dart';

abstract class TestRepo<T extends TestObj> {
  final StampRepo stampRepo;
  final SubUser subUser;
  final AuthUser authUser;
  TestRepo(
      {required this.stampRepo, required this.authUser, required this.subUser});

  Stream<T?> get obj;

  submit(DateTime submitTime);
  setValue(T obj);
  cancel();
}
