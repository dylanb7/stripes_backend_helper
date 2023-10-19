import 'package:stripes_backend_helper/RepositoryBase/TestBase/BlueDye/blue_dye_impl.dart';
import 'package:stripes_backend_helper/TestingReposImpl/test_question_repo.dart';

import 'QuestionModel/question.dart';
import 'QuestionModel/response.dart';
import 'RepositoryBase/AccessBase/base_access_repo.dart';
import 'RepositoryBase/AuthBase/auth_user.dart';
import 'RepositoryBase/AuthBase/base_auth_repo.dart';
import 'RepositoryBase/QuestionBase/question_repo_base.dart';
import 'RepositoryBase/StampBase/base_stamp_repo.dart';
import 'RepositoryBase/StampBase/stamp.dart';
import 'RepositoryBase/SubBase/base_sub_repo.dart';
import 'RepositoryBase/SubBase/sub_user.dart';
import 'RepositoryBase/TestBase/base_test_repo.dart';
import 'TestingReposImpl/test_access.dart';
import 'TestingReposImpl/test_auth_repo.dart';
import 'TestingReposImpl/test_stamp_repo.dart';
import 'TestingReposImpl/test_sub_repo.dart';
import 'TestingReposImpl/test_test_repo.dart';

abstract class StripesRepoPackage {
  AccessCodeRepo access();

  AuthRepo auth();

  SubUserRepo sub({required AuthUser user});

  StampRepo<Response> stamp(
      {required AuthUser user,
      required SubUser subUser,
      required QuestionHome home});

  TestRepo<BlueDyeTest> test(
      {required AuthUser user,
      required SubUser subUser,
      required StampRepo stampRepo});

  QuestionRepo questions({required AuthUser user});
}

class LocalRepoPackage extends StripesRepoPackage {
  @override
  AccessCodeRepo access() {
    return TestAccessRepo();
  }

  @override
  AuthRepo auth() {
    return TestAuth();
  }

  @override
  StampRepo<Response<Question>> stamp(
      {required AuthUser user,
      required SubUser subUser,
      required QuestionHome home}) {
    return TestResponseRepo(subUser);
  }

  @override
  SubUserRepo sub({required AuthUser user}) {
    return TestSubRepo(user);
  }

  @override
  TestRepo<BlueDyeTest> test(
      {required AuthUser user,
      required SubUser subUser,
      required StampRepo<Stamp> stampRepo}) {
    return TestTestRepo(stampRepo, subUser);
  }

  @override
  QuestionRepo<QuestionHome> questions({required AuthUser user}) {
    return TestQuestionRepo();
  }
}

class LocalStockedRepoPackage extends StripesRepoPackage {
  @override
  AccessCodeRepo access() {
    return TestAccessRepo();
  }

  @override
  AuthRepo auth() {
    return TestAuth();
  }

  @override
  QuestionRepo<QuestionHome> questions({required AuthUser user}) {
    return TestQuestionRepo();
  }

  @override
  StampRepo<Response<Question>> stamp(
      {required AuthUser user,
      required SubUser subUser,
      required QuestionHome home}) {
    return TestResponseRepo.filled(subUser, 200);
  }

  @override
  SubUserRepo sub({required AuthUser user}) {
    return TestSubRepo(user);
  }

  @override
  TestRepo<BlueDyeTest> test(
      {required AuthUser user,
      required SubUser subUser,
      required StampRepo<Stamp> stampRepo}) {
    return TestTestRepo(stampRepo, subUser);
  }
}
