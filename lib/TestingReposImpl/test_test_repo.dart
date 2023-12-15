import 'dart:async';

import 'package:flutter/material.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_backend_helper/RepositoryBase/AuthBase/auth_user.dart';
import 'package:stripes_backend_helper/RepositoryBase/SubBase/sub_user.dart';
import 'package:stripes_backend_helper/RepositoryBase/TestBase/BlueDye/blue_dye_impl.dart';

import 'package:stripes_backend_helper/TestingReposImpl/test_question_repo.dart';

import '../RepositoryBase/StampBase/base_stamp_repo.dart';
import '../RepositoryBase/TestBase/BlueDye/blue_dye_response.dart';
import '../RepositoryBase/TestBase/base_test_repo.dart';

final Map<SubUser, BlueDyeObj?> _repo = {};

class TestTestRepo extends TestsRepo {
  final StreamController<BlueDyeTest?> _streamController = StreamController();

  TestTestRepo(StampRepo testResponseRepo, SubUser subUser)
      : super(
            stampRepo: testResponseRepo,
            subUser: subUser,
            authUser: const AuthUser.empty(),
            questionRepo: TestQuestionRepo(),
            tests: []) {
    _repo[subUser] = null;
    _streamController.add(null);
  }
}

class BlueDyeTest extends Test<BlueDyeObj> {
  final StreamController<BlueDyeObj?> _streamController = StreamController();

  BlueDyeTest(
      {required super.stampRepo,
      required super.authUser,
      required super.subUser,
      required super.questionRepo})
      : super(listensTo: {Symptoms.BM});

  @override
  String getName(BuildContext context) {
    return "Blue Dye Test";
  }

  @override
  Stream<BlueDyeObj?> get obj => _streamController.stream;

  @override
  Future<void> onDelete(Response<Question> stamp, String type) {
    // TODO: implement onDelete
    throw UnimplementedError();
  }

  @override
  Future<void> onEdit(Response<Question> stamp, String type) {
    // TODO: implement onEdit
    throw UnimplementedError();
  }

  @override
  Future<void> onSubmit(Response<Question> stamp, String type) {
    // TODO: implement onSubmit
    throw UnimplementedError();
  }

  @override
  Widget? pathAdditions(BuildContext context, String type) {
    // TODO: implement pathAdditions
    throw UnimplementedError();
  }

  @override
  List<Question> recordAdditions(BuildContext context, String type) {
    return [
      MultipleChoice(
          id: "BlueDyeQuestion",
          prompt: "Did your BM contain blue/green color?",
          type: type,
          choices: const ["Yes", "No"])
    ];
  }

  @override
  Future<void> cancel() async {
    _repo[subUser] = null;
    _streamController.add(null);
  }

  @override
  Future<void> setValue(BlueDyeObj obj) async {
    _repo[subUser] = obj;
    _streamController.add(_repo[subUser]!);
  }

  @override
  Future<void> submit(DateTime submitTime) async {
    stampRepo.addStamp(BlueDyeResp.from(_repo[subUser]!));
    cancel();
  }
}
