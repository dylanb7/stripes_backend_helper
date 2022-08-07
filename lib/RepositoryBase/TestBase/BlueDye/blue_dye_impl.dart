import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_repo_base.dart';
import 'package:stripes_backend_helper/RepositoryBase/TestBase/test_obj.dart';
import 'package:stripes_backend_helper/date_format.dart';

import 'bm_test_log.dart';

// ignore: constant_identifier_names
const String FINISHED_KEY = 'finished_eating';

class BlueDyeTest extends TestObj {
  Duration? finishedEating;

  List<BMTestLog> logs;

  BlueDyeTest(
      {required DateTime startTime, this.finishedEating, required this.logs})
      : super(startTime: startTime);

  BlueDyeTest.fromJson(Map<String, dynamic> json, QuestionHome home)
      : finishedEating = toDuration(json[FINISHED_KEY]),
        logs = deserializeLogs(json, home),
        super.fromJson(json);

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        if (finishedEating != null)
          FINISHED_KEY: finishedEating!.inMilliseconds,
        ...serializeLogs(logs),
      };

  setLogs(List<BMTestLog> newLogs) {
    logs = newLogs;
  }

  addLog(BMTestLog log) {
    logs.add(log);
  }

  removeLog(BMTestLog log) {
    logs.removeWhere((element) => element.stamp == log.stamp);
  }

  updateLog(BMTestLog log) {
    final int index = logs.indexWhere((element) => element.stamp == log.stamp);
    if (index < 0 || index >= logs.length) return;
    logs[index] = log;
  }

  set setStart(DateTime start) => startTime = start;

  set finished(Duration end) => finishedEating = end;

  DateTime? get start => startTime;

  Duration? get eatingDone => finishedEating;

  @override
  String toString() {
    return 'start: $startTime, duration: $finishedEating, logs: $logs';
  }
}

enum TestState {
  initial,
  started,
  logs,
  logsSubmit;

  bool get testInProgress => this != TestState.initial;
}

TestState stateFromTestOBJ(BlueDyeTest? obj) {
  if (obj == null) return TestState.initial;
  if (obj.finishedEating == null) return TestState.started;
  bool startsBlue = false;
  bool endsNormal = false;
  for (BMTestLog log in obj.logs) {
    if (log.isBlue) {
      startsBlue = true;
    } else if (startsBlue) {
      endsNormal = true;
    }
  }
  if (endsNormal) return TestState.logsSubmit;
  return TestState.logs;
}

DateTime? toDate(int? time) {
  if (time == null) return null;
  return dateFromStamp(time);
}

Duration? toDuration(int? time) {
  if (time == null) return null;
  return Duration(milliseconds: time);
}

List<BMTestLog> deserializeLogs(Map<String, dynamic> json, QuestionHome home) {
  final List<BMTestLog> res = [];
  for (int i = 0; true; i++) {
    final String key = '$i';
    if (!json.containsKey(key)) {
      return res;
    }
    res.add(BMTestLog.fromJson(json[key], home));
  }
}

Map<String, dynamic> serializeLogs(List<BMTestLog> logs) {
  Map<String, dynamic> res = {};
  for (int i = 0; i < logs.length; i++) {
    res['$i'] = logs[i].toJson();
  }
  return res;
}
