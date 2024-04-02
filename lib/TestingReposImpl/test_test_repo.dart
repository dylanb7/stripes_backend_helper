import 'package:stripes_backend_helper/RepositoryBase/SubBase/sub_user.dart';

import '../RepositoryBase/StampBase/base_stamp_repo.dart';
import '../RepositoryBase/TestBase/base_test_repo.dart';

class TestTestRepo extends TestsRepo {
  TestTestRepo(StampRepo testResponseRepo, SubUser subUser) : super(tests: []);
}
