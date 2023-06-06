import 'package:flutter/foundation.dart';
import 'package:stripes_backend_helper/db_keys.dart';
import 'package:uuid/uuid.dart';

@immutable
class SubUser {
  final String uid;

  final String name;

  final String gender;

  final int birthYear;

  final bool isControl;

  SubUser(
      {required this.name,
      required this.gender,
      required this.birthYear,
      required this.isControl,
      String? id})
      : uid = id ?? const Uuid().v4();

  factory SubUser.empty() =>
      SubUser(name: '', gender: '', birthYear: 0, isControl: false, id: '');

  factory SubUser.marker() => SubUser(
      name: '',
      gender: '',
      birthYear: 0,
      isControl: false,
      id: '|single_user|');

  factory SubUser.fromJson({required Map<String, dynamic> json}) => SubUser(
      name: json[NAME_FIELD],
      gender: json[GENDER_FIELD],
      birthYear: json[BIRTH_YEAR_FIELD],
      isControl: json.containsKey(CONTROL_FIELD) ? json[CONTROL_FIELD] : false,
      id: json[SUB_ID]);

  Map<String, dynamic> toJson() => {
        SUB_ID: uid,
        NAME_FIELD: name,
        GENDER_FIELD: gender,
        BIRTH_YEAR_FIELD: birthYear,
        CONTROL_FIELD: isControl
      };

  @override
  String toString() {
    return 'name($name) | gender($gender) | birth year($birthYear) | control($isControl)';
  }

  static bool isEmpty(SubUser user) => user.uid == '';

  static bool isMarker(SubUser user) => user.uid == '|single_user|';
}
