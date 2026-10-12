import 'package:stripes_backend_helper/SyncOperations/manager_base.dart';
import 'package:stripes_backend_helper/TestingReposImpl/test_question_repo.dart';

import 'QuestionModel/question.dart';
import 'QuestionModel/response.dart';
import 'RepositoryBase/AccessBase/base_access_repo.dart';
import 'RepositoryBase/AuthBase/auth_user.dart';
import 'RepositoryBase/AuthBase/base_auth_repo.dart';
import 'RepositoryBase/QuestionBase/question_repo_base.dart';
import 'RepositoryBase/StampBase/base_stamp_repo.dart';
import 'RepositoryBase/SubBase/base_sub_repo.dart';
import 'RepositoryBase/SubBase/sub_user.dart';
import 'TestingReposImpl/test_access.dart';
import 'TestingReposImpl/test_auth_repo.dart';
import 'TestingReposImpl/test_stamp_repo.dart';
import 'TestingReposImpl/test_sub_repo.dart';
import 'RepositoryBase/EntryBase/base_entry_repo.dart';
import 'RepositoryBase/ModularTestBase/modular_test_base_repo.dart';
import 'TestingReposImpl/test_entry_repo.dart';

abstract class StripesRepoPackage {
  AccessCodeRepo access();

  AuthRepo auth();

  SubUserRepo sub({required AuthUser user});

  StampRepo<Response> stamp(
      {required AuthUser user,
      required SubUser subUser,
      required QuestionRepo questionRepo});

  ModularTestsRepo? test(
          {required AuthUser user, required SubUser subUser}) =>
      null;

  QuestionRepo questions({required AuthUser user, required SubUser subUser});

  EntryRepo? entry({required AuthUser user, required SubUser subUser}) => null;

  SyncManagerBase? syncManager({required SubUser subUser});
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
      required QuestionRepo questionRepo}) {
    return TestResponseRepo(subUser);
  }

  @override
  SubUserRepo sub({required AuthUser user}) {
    return TestSubRepo(user);
  }

  @override
  ModularTestsRepo? test(
      {required AuthUser user, required SubUser subUser}) {
    return null;
  }

  @override
  QuestionRepo<QuestionHome> questions(
      {required AuthUser user, required SubUser subUser}) {
    return TestQuestionRepo(subUser: subUser);
  }

  @override
  EntryRepo entry({required AuthUser user, required SubUser subUser}) {
    return TestEntryRepo(user, subUser);
  }

  @override
  SyncManagerBase? syncManager({required SubUser subUser}) {
    return null;
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
  QuestionRepo<QuestionHome> questions(
      {required AuthUser user, required SubUser subUser}) {
    return TestQuestionRepo(subUser: subUser);
  }

  @override
  StampRepo<Response<Question>> stamp(
      {required AuthUser user,
      required SubUser subUser,
      required QuestionRepo questionRepo}) {
    return TestResponseRepo.filled(subUser, 200);
  }

  @override
  SubUserRepo sub({required AuthUser user}) {
    return TestSubRepo(user);
  }

  @override
  ModularTestsRepo? test(
      {required AuthUser user, required SubUser subUser}) {
    return null;
  }

  @override
  EntryRepo entry({required AuthUser user, required SubUser subUser}) {
    return TestEntryRepo(user, subUser);
  }

  @override
  SyncManagerBase? syncManager({required SubUser subUser}) {
    return null;
  }
}
