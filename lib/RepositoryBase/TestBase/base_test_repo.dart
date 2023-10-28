import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_repo_base.dart';
import 'package:stripes_backend_helper/RepositoryBase/StampBase/base_stamp_repo.dart';
import 'package:stripes_backend_helper/RepositoryBase/SubBase/sub_user.dart';

import '../AuthBase/auth_user.dart';
import 'test_obj.dart';

abstract class TestRepo<T extends TestObj> {
  final StampRepo stampRepo;
  final SubUser subUser;
  final AuthUser authUser;
  final QuestionRepo questionRepo;
  TestRepo(
      {required this.stampRepo,
      required this.authUser,
      required this.subUser,
      required this.questionRepo});

  Stream<T?> get obj;

  Future<void> submit(DateTime submitTime);
  Future<void> setValue(T obj);
  Future<void> cancel();
}
