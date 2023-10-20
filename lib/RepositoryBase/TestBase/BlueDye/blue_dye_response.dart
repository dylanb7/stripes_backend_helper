// ignore_for_file: constant_identifier_names

import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_backend_helper/RepositoryBase/TestBase/BlueDye/blue_dye_impl.dart';
import 'package:stripes_backend_helper/date_format.dart';
import 'package:stripes_backend_helper/db_keys.dart';

const String EATING_DURATION = 'mealDurationKey';
const String NORMAL_BOWEL_MOVEMENTS = 'normalBowelMovementsKey';
const String BLUE_BOWEL_MOVEMENTS = 'blueBowelMovementsKey';
const String FIRST_BLUE = 'firstBlueKey';
const String LAST_BLUE = 'lastBlueKey';

class BlueDyeResp extends Response {
  final DateTime startEating;
  final Duration eatingDuration;
  final int normalBowelMovements;
  final int blueBowelMovements;
  final DateTime firstBlue;
  final DateTime lastBlue;
  BlueDyeResp(
      {required this.startEating,
      required this.eatingDuration,
      required this.normalBowelMovements,
      required this.blueBowelMovements,
      required this.firstBlue,
      required this.lastBlue,
      super.id})
      : super(
            question:
                const Check(type: 'Test', id: '', prompt: 'Blue Dye Test'),
            stamp: dateToStamp(startEating));

  //test obj must have atleast one log
  factory BlueDyeResp.from(BlueDyeTest obj) {
    if (obj.logs.isEmpty) {
      throw 'Insuffient logs';
    }
    return BlueDyeResp(
        startEating: obj.start!,
        eatingDuration: obj.finishedEating!,
        blueBowelMovements: obj.logs.where((element) => element.isBlue).length,
        normalBowelMovements:
            obj.logs.where((element) => !element.isBlue).length,
        firstBlue: dateFromStamp(
            obj.logs.firstWhere((element) => element.isBlue).stamp),
        lastBlue: dateFromStamp(
            obj.logs.lastWhere((element) => element.isBlue).stamp));
  }

  factory BlueDyeResp.fromJson(Map<String, dynamic> json) => BlueDyeResp(
      startEating: dateFromStamp(json[STAMP_FIELD]),
      eatingDuration: Duration(milliseconds: json[EATING_DURATION]),
      normalBowelMovements: json[NORMAL_BOWEL_MOVEMENTS],
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
