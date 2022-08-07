import 'package:flutter/material.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';

abstract class TestObj {
  DateTime startTime;

  TestObj({required this.startTime});

  @mustCallSuper
  TestObj.fromJson(Map<String, dynamic> json) : startTime = json[STAMP_FIELD];

  @mustCallSuper
  Map<String, dynamic> toJson() => {
        STAMP_FIELD: dateToStamp(startTime),
      };
}
