import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';

@immutable
class Stamp with EquatableMixin {
  final int stamp;
  final String type;

  const Stamp({required this.stamp, required this.type});

  @mustCallSuper
  Stamp.fromJson(Map<String, dynamic> json)
      : stamp = json[STAMP_FIELD],
        type = json[TYPE_FIELD];
  @mustCallSuper
  Map<String, dynamic> toJson() => {STAMP_FIELD: stamp, TYPE_FIELD: type};

  @override
  @mustCallSuper
  List<Object?> get props => [stamp, type];
}
