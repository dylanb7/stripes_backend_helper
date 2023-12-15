import 'package:flutter/material.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_repo_base.dart';
import 'package:stripes_backend_helper/RepositoryBase/StampBase/base_stamp_repo.dart';
import 'package:stripes_backend_helper/RepositoryBase/SubBase/sub_user.dart';

import '../AuthBase/auth_user.dart';
import 'test_obj.dart';

abstract class TestsRepo {
  final StampRepo stampRepo;
  final SubUser subUser;
  final AuthUser authUser;
  final QuestionRepo questionRepo;

  TestsRepo(
      {required this.stampRepo,
      required this.authUser,
      required this.subUser,
      required this.questionRepo});

  List<Test> getTests();

  List<Test> _getApplicable(String type) {
    List<Test> tests = getTests();
    return tests
        .where((test) => test.listensTo.contains(type))
        .toList(growable: false);
  }

  List<Widget> getPathAdditions(BuildContext context, String type) {
    List<Test> tests = _getApplicable(type);
    List<Widget> additions = [];
    for (final Test test in tests) {
      final Widget? pathAddition = test.pathAdditions(context, type);
      if (pathAddition != null) {
        additions.add(pathAddition);
      }
    }
    return additions;
  }

  List<Question> getRecordAdditions(BuildContext context, String type) {
    List<Test> tests = _getApplicable(type);
    List<Question> additions = [];
    for (final Test test in tests) {
      additions.addAll(test.recordAdditions(context, type));
    }
    return additions;
  }

  Future<void> onResponseSubmit(Response stamp, String type) async {
    List<Test> tests = _getApplicable(type);
    for (final Test test in tests) {
      await test.onSubmit(stamp, type);
    }
  }

  Future<void> onResponseEdit(Response stamp, String type) async {
    List<Test> tests = _getApplicable(type);
    for (final Test test in tests) {
      await test.onEdit(stamp, type);
    }
  }

  Future<void> onResponseDelete(Response stamp, String type) async {
    List<Test> tests = _getApplicable(type);
    for (final Test test in tests) {
      await test.onDelete(stamp, type);
    }
  }
}

abstract class Test<T extends TestObj> {
  final StampRepo stampRepo;
  final SubUser subUser;
  final AuthUser authUser;
  final QuestionRepo questionRepo;

  final Set<String> listensTo;

  Test({
    required this.stampRepo,
    required this.authUser,
    required this.subUser,
    required this.questionRepo,
    required this.listensTo,
  });

  Stream<T?> get obj;

  String getName(BuildContext context);
  List<Question> recordAdditions(BuildContext context, String type);
  Widget? pathAdditions(BuildContext context, String type);
  Future<void> onSubmit(Response stamp, String type);
  Future<void> onEdit(Response stamp, String type);
  Future<void> onDelete(Response stamp, String type);
  Future<void> submit(DateTime submitTime);
  Future<void> setValue(T obj);
  Future<void> cancel();
}
