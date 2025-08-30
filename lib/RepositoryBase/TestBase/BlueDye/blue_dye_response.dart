// ignore_for_file: constant_identifier_names

import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_backend_helper/RepositoryBase/TestBase/BlueDye/blue_dye_impl.dart';
import 'package:stripes_backend_helper/RepositoryBase/TestBase/BlueDye/bm_test_log.dart';
import 'package:stripes_backend_helper/date_format.dart';
import 'package:stripes_backend_helper/db_keys.dart';

const String EATING_DURATION = 'mealDurationKey';
const String NORMAL_BOWEL_MOVEMENTS = 'normalBowelMovementsKey';
const String BLUE_BOWEL_MOVEMENTS = 'blueBowelMovementsKey';
const String FIRST_BLUE = 'firstBlueKey';
const String LAST_BLUE = 'lastBlueKey';

class BlueDyeResp extends ResponseWrap {
  final DateTime startEating;
  final Duration eatingDuration;
  final DateTime? finishedEatingTime;
  final int normalBowelMovements;
  final int blueBowelMovements;
  final AmountConsumed amountConsumed;
  final List<BMTestLog> logs;
  final DateTime firstBlue;
  final DateTime lastBlue;
  BlueDyeResp(
      {required this.startEating,
      required this.eatingDuration,
      required this.normalBowelMovements,
      required this.blueBowelMovements,
      this.finishedEatingTime,
      required this.logs,
      required this.amountConsumed,
      required this.firstBlue,
      required this.lastBlue,
      super.group,
      super.id})
      : super(
            responses: logs,
            type: logs.isEmpty ? 'Blue Dye Response' : logs.first.type,
            stamp: dateToStamp(startEating));

  //test obj must have atleast one log
  factory BlueDyeResp.from(BlueDyeState obj) {
    if (obj.logs.isEmpty) {
      throw 'Insuffient logs';
    }
    return BlueDyeResp(
        startEating: obj.startTime!,
        eatingDuration: obj.finishedEating!,
        blueBowelMovements: obj.logs.where((element) => element.isBlue).length,
        normalBowelMovements:
            obj.logs.where((element) => !element.isBlue).length,
        logs: obj.logs,
        firstBlue: dateFromStamp(
            obj.logs.firstWhere((element) => element.isBlue).stamp),
        amountConsumed: obj.amountConsumed ?? AmountConsumed.undetermined,
        lastBlue: dateFromStamp(
            obj.logs.lastWhere((element) => element.isBlue).stamp),
        finishedEatingTime: obj.finishedEatingTime);
  }

  //TODO: add serialization for logs
  factory BlueDyeResp.fromJson(Map<String, dynamic> json) => BlueDyeResp(
      startEating: dateFromStamp(json[STAMP_FIELD]),
      eatingDuration: Duration(milliseconds: json[EATING_DURATION]),
      normalBowelMovements: json[NORMAL_BOWEL_MOVEMENTS],
      amountConsumed: parseAmountConsumed(json[AMOUNT_CONSUMED]) ??
          AmountConsumed.undetermined,
      logs: const [],
      blueBowelMovements: json[BLUE_BOWEL_MOVEMENTS],
      firstBlue: dateFromStamp(json[FIRST_BLUE]),
      lastBlue: dateFromStamp(json[LAST_BLUE]));

  @override
  // ignore: must_call_super
  Map<String, dynamic> toJson() {
    return {
      STAMP_FIELD: dateToStamp(startEating),
      EATING_DURATION: eatingDuration.inMilliseconds,
      NORMAL_BOWEL_MOVEMENTS: normalBowelMovements,
      BLUE_BOWEL_MOVEMENTS: blueBowelMovements,
      FIRST_BLUE: dateToStamp(firstBlue),
      LAST_BLUE: dateToStamp(lastBlue),
    };
  }
}
