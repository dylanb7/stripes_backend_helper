// ignore_for_file: constant_identifier_names

import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_repo_base.dart';
import 'package:stripes_backend_helper/RepositoryBase/TestBase/test_obj.dart';
import 'package:stripes_backend_helper/date_format.dart';

import 'bm_test_log.dart';

const String FINISHED_KEY = 'finished_eating';
const String FINISHED_TIME_KEY = 'finished_time';
const String AMOUNT_CONSUMED = 'amount_consumed';
const String TIMER_START = 'timer_start';
const String PAUSE_TIME = 'pause_time';

class BlueDyeObj extends TestObj {
  Duration? finishedEating;

  DateTime? finishedEatingTime;

  DateTime? timerStart;

  DateTime? pauseTime;

  AmountConsumed? amountConsumed;

  List<BMTestLog> logs;

  BlueDyeObj(
      {DateTime? startTime,
      this.finishedEating,
      this.finishedEatingTime,
      this.timerStart,
      this.pauseTime,
      this.amountConsumed,
      required this.logs,
      super.id})
      : super(startTime: startTime);

  BlueDyeObj.fromJson(Map<String, dynamic> json, QuestionHome home)
      : finishedEating = toDuration(json[FINISHED_KEY]),
        finishedEatingTime = json.containsKey(FINISHED_TIME_KEY)
            ? dateFromStamp(json[FINISHED_TIME_KEY])
            : null,
        amountConsumed = parseAmountConsumed(json[AMOUNT_CONSUMED]),
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
        if (timerStart != null) TIMER_START: dateToStamp(timerStart!),
        if (pauseTime != null) PAUSE_TIME: dateToStamp(pauseTime!),
        if (amountConsumed != null) AMOUNT_CONSUMED: amountConsumed.toString(),
        ...serializeLogs(logs),
      };

  BlueDyeObj copyWith(
          {DateTime? startTime,
          Duration? finishedEating,
          DateTime? finishedEatingTime,
          DateTime? pauseTime,
          DateTime? timerStart,
          AmountConsumed? amountConsumed,
          List<BMTestLog>? logs}) =>
      BlueDyeObj(
          id: id,
          startTime: startTime ?? this.startTime,
          finishedEating: finishedEating ?? this.finishedEating,
          finishedEatingTime: finishedEatingTime ?? this.finishedEatingTime,
          amountConsumed: amountConsumed ?? this.amountConsumed,
          pauseTime: pauseTime ?? this.pauseTime,
          timerStart: timerStart ?? this.timerStart,
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

enum AmountConsumed {
  undetermined,
  halfOrLess,
  half,
  moreThanHalf,
  all;

  @override
  String toString() {
    switch (this) {
      case AmountConsumed.undetermined:
        return "Unable to determine amount consumed";
      case AmountConsumed.halfOrLess:
        return "Less than half of blue meal";
      case AmountConsumed.half:
        return "Half of blue meal";
      case AmountConsumed.moreThanHalf:
        return "More than half of blue meal";
      case AmountConsumed.all:
        return "All of blue meal";
    }
  }
}

const Map<String, AmountConsumed> parseMap = {
  "Unable to determine amount consumed": AmountConsumed.undetermined,
  "Less than half of blue meal": AmountConsumed.halfOrLess,
  "Half of blue meal": AmountConsumed.half,
  "More than half of blue meal": AmountConsumed.moreThanHalf,
  "All of blue meal": AmountConsumed.all
};

AmountConsumed? parseAmountConsumed(String? value) {
  if (value == null) return null;
  return parseMap[value];
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
