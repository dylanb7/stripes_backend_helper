import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_repo_base.dart';
import 'package:stripes_backend_helper/RepositoryBase/TestBase/test_obj.dart';
import 'package:stripes_backend_helper/date_format.dart';

import 'bm_test_log.dart';

// ignore: constant_identifier_names
const String FINISHED_KEY = 'finished_eating';
// ignore: constant_identifier_names
const String FINISHED_TIME_KEY = 'finished_time';

class BlueDyeObj extends TestObj {
  Duration? finishedEating;

  DateTime? finishedEatingTime;

  List<BMTestLog> logs;

  BlueDyeObj(
      {DateTime? startTime,
      this.finishedEating,
      this.finishedEatingTime,
      required this.logs,
      super.id})
      : super(startTime: startTime);

  BlueDyeObj.fromJson(Map<String, dynamic> json, QuestionHome home)
      : finishedEating = toDuration(json[FINISHED_KEY]),
        finishedEatingTime = json.containsKey(FINISHED_TIME_KEY)
            ? dateFromStamp(json[FINISHED_TIME_KEY])
            : null,
        logs = deserializeLogs(json, home),
        super.fromJson(json);

  BlueDyeObj.empty()
      : logs = [],
        super(startTime: null);

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        if (finishedEating != null)
          FINISHED_KEY: finishedEating!.inMilliseconds,
        if (finishedEatingTime != null)
          FINISHED_TIME_KEY: dateToStamp(finishedEatingTime!),
        ...serializeLogs(logs),
      };

  BlueDyeObj copyWith(
          {DateTime? startTime,
          Duration? finishedEating,
          DateTime? finishedEatingTime,
          List<BMTestLog>? logs}) =>
      BlueDyeObj(
          id: id,
          startTime: startTime ?? this.startTime,
          finishedEating: finishedEating ?? this.finishedEating,
          finishedEatingTime: finishedEatingTime ?? this.finishedEatingTime,
          logs: logs ?? this.logs);

  @override
  String toString() {
    return 'start: $startTime, duration: $finishedEating, finish time: $finishedEatingTime, logs: $logs';
  }
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

enum TestState {
  initial,
  started,
  logs,
  logsSubmit;

  bool get testInProgress => this != TestState.initial;
}

TestState stateFromTestOBJ(BlueDyeObj? obj) {
  if (obj == null || obj.startTime == null) return TestState.initial;
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
