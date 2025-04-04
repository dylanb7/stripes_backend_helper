import 'dart:async';
import 'dart:math';

import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_backend_helper/RepositoryBase/AuthBase/auth_user.dart';

import 'package:stripes_backend_helper/RepositoryBase/SubBase/sub_user.dart';
import 'package:stripes_backend_helper/TestingReposImpl/test_question_repo.dart';
import 'package:stripes_backend_helper/date_format.dart';

import '../RepositoryBase/StampBase/base_stamp_repo.dart';

Map<SubUser, List<Response>> _responses = {};

class TestResponseRepo extends StampRepo<Response> {
  final StreamController<List<Response>> _stream = StreamController();

  TestResponseRepo(SubUser subUser)
      : super(
            authUser: const AuthUser.empty(),
            currentUser: subUser,
            questionRepo: TestQuestionRepo()) {
    if (!_responses.containsKey(currentUser)) {
      _responses[currentUser] = [];
    }
    _stream.add(_responses[currentUser]!);
  }

  TestResponseRepo.filled(SubUser current, int amount, [int daysBack = 31])
      : super(
            authUser: const AuthUser.empty(),
            currentUser: current,
            questionRepo: TestQuestionRepo()) {
    if (!_responses.containsKey(currentUser)) {
      _responses[currentUser] = [];
    }
    final DateTime now = DateTime.now();
    final Random random = Random(2539);
    final List<Question> choices = QuestionHomeInst().all.values.toList();

    for (int i = 0; i < amount; i++) {
      final Duration sub = Duration(
          days: random.nextInt(daysBack),
          hours: random.nextInt(23),
          minutes: random.nextInt(59),
          seconds: random.nextInt(59));
      final DateTime submitTime = now.subtract(sub);
      final int stamp = dateToStamp(submitTime);
      final Question question = choices[random.nextInt(choices.length)];
      Response? res;
      if (question is Numeric) {
        res = NumericResponse(
            question: question,
            stamp: stamp,
            response: random.nextInt(((question.max ?? 5) - 1).toInt()) +
                (question.min ?? 1));
      } else if (question is Check) {
        res = Selected(question: question, stamp: stamp);
      } else if (question is AllThatApply) {
        final int selections = random.nextInt(question.choices.length);
        res = AllResponse(
            stamp: stamp,
            question: question,
            responses: List.generate(
                    selections, (_) => random.nextInt(question.choices.length))
                .toSet()
                .toList());
      } else if (question is MultipleChoice) {
        final int selection = random.nextInt(question.choices.length);
        res = MultiResponse(stamp: stamp, question: question, index: selection);
      }

      if (res != null) {
        _responses[currentUser]!.add(DetailResponse(
            description: "", responses: [res], stamp: res.stamp));
      }
    }
    _responses[currentUser]!.sort(
      (a, b) => b.stamp.compareTo(a.stamp),
    );
    _stream.add(_responses[currentUser]!);
  }

  TestResponseRepo.filledSinguler(SubUser current, int amount, Numeric question,
      [int daysBack = 31])
      : super(
            authUser: const AuthUser.empty(),
            currentUser: current,
            questionRepo: TestQuestionRepo()) {
    if (!_responses.containsKey(currentUser)) {
      _responses[currentUser] = [];
    }
    final DateTime now = DateTime.now();
    final Random random = Random(2539);
    for (int i = 0; i < amount; i++) {
      final Duration sub = Duration(
          days: random.nextInt(daysBack),
          hours: random.nextInt(23),
          minutes: random.nextInt(59),
          seconds: random.nextInt(59));
      _responses[currentUser]!.add(NumericResponse(
          question: question,
          stamp: dateToStamp(now.subtract(sub)),
          response: random.nextInt(4) + 1));
    }
    _responses[currentUser]!.sort(
      (a, b) => b.stamp.compareTo(a.stamp),
    );
    _stream.add(_responses[currentUser]!);
  }

  @override
  Future<bool> addStamp(Response stamp) async {
    _responses[currentUser]!.add(stamp);
    _responses[currentUser]!.sort(
      (a, b) => b.stamp.compareTo(a.stamp),
    );
    _stream.add(_responses[currentUser]!);
    return true;
  }

  @override
  Future<bool> removeStamp(Response stamp) async {
    _responses[currentUser]!
        .removeWhere((element) => element.stamp == stamp.stamp);
    _stream.add(_responses[currentUser]!);
    return true;
  }

  @override
  Stream<List<Response>> get stamps => _stream.stream;

  @override
  Future<bool> updateStamp(Response stamp) async {
    final int index = _responses[currentUser]!
        .indexWhere((element) => element.stamp == stamp.stamp);
    if (index < 0) return false;
    _responses[currentUser]![index] = stamp;
    _stream.add(_responses[currentUser]!);
    return true;
  }

  @override
  Future<void> refresh() async {}
}
