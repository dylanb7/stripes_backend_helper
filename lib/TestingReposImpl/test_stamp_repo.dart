import 'dart:async';
import 'dart:math';

import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_backend_helper/RepositoryBase/AuthBase/auth_user.dart';

import 'package:stripes_backend_helper/RepositoryBase/SubBase/sub_user.dart';
import 'package:stripes_backend_helper/date_format.dart';

import '../RepositoryBase/StampBase/base_stamp_repo.dart';

Map<SubUser, List<Response>> _responses = {};

class TestResponseRepo extends StampRepo<Response> {
  final StreamController<List<Response>> _stream = StreamController();

  TestResponseRepo(SubUser subUser)
      : super(authUser: AuthUser.empty(), currentUser: subUser) {
    _stream.add([]);
  }

  TestResponseRepo.filledSinguler(SubUser current, int amount, Numeric question,
      [int daysBack = 31])
      : super(authUser: AuthUser.empty(), currentUser: current) {
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
  addStamp(Response stamp) {
    _responses[currentUser]!.add(stamp);
    _responses[currentUser]!.sort(
      (a, b) => b.stamp.compareTo(a.stamp),
    );
    _stream.add(_responses[currentUser]!);
  }

  @override
  removeStamp(Response stamp) {
    _responses[currentUser]!
        .removeWhere((element) => element.stamp == stamp.stamp);
    _stream.add(_responses[currentUser]!);
  }

  @override
  Stream<List<Response>> get stamps => _stream.stream;

  @override
  updateStamp(Response stamp) {
    final int index = _responses[currentUser]!
        .indexWhere((element) => element.stamp == stamp.stamp);
    if (index < 0) return;
    _responses[currentUser]![index] = stamp;
    _stream.add(_responses[currentUser]!);
  }
}
