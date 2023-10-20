// ignore_for_file: constant_identifier_names, must_call_super

import 'package:equatable/equatable.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';

const String DETAIL_RES_KEY = 'detail_res';
const String IS_BLUE_KEY = 'is_blue';

class BMTestLog extends Response with EquatableMixin {
  final DetailResponse response;

  final bool isBlue;

  BMTestLog({required this.response, required this.isBlue, super.id})
      : super(question: Question.empty(), stamp: response.stamp);

  BMTestLog.fromJson(Map<String, dynamic> json, QuestionHome home)
      : response = DetailResponse.fromJson(json, home),
        isBlue = json[IS_BLUE_KEY],
        super(question: Question.empty(), stamp: json[STAMP_FIELD]);

  @override
  Map<String, dynamic> toJson() {
    return {
      DETAIL_RES_KEY: response.toJson(),
      IS_BLUE_KEY: isBlue,
    };
  }

  @override
  List<Object?> get props => [response, isBlue];

  @override
  String toString() {
    return toJson().toString();
  }
}
