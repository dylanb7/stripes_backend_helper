import 'package:stripes_backend_helper/RepositoryBase/AuthBase/auth_user.dart';
import 'package:stripes_backend_helper/RepositoryBase/SubBase/sub_user.dart';

import 'package:stripes_backend_helper/TestingReposImpl/test_question_repo.dart';

import '../RepositoryBase/StampBase/base_stamp_repo.dart';
import '../RepositoryBase/TestBase/base_test_repo.dart';

class TestTestRepo extends TestsRepo {
  TestTestRepo(StampRepo testResponseRepo, SubUser subUser) : super(tests: []);
}
