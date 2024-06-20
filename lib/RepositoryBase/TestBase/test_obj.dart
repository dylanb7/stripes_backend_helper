import 'package:flutter/material.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';

abstract class TestObj {
  DateTime? startTime;

  final String? id;

  TestObj({required this.startTime, this.id});

  TestObj.fromJson(Map<String, dynamic> json)
      : startTime = json[STAMP_FIELD],
        id = json[STAMP_ID];

  @mustCallSuper
  Map<String, dynamic> toJson() => {
        STAMP_FIELD: startTime != null ? dateToStamp(startTime!) : null,
        STAMP_ID: id
      };
}
