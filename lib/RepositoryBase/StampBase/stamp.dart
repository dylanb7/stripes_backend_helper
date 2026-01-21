import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';

@immutable
class Stamp with EquatableMixin {
  final String? id;
  final int stamp;
  final String type;
  final String? group;

  const Stamp({required this.stamp, required this.type, this.id, this.group});

  Stamp.fromJson(Map<String, dynamic> json)
      : stamp = json[STAMP_FIELD],
        type = json[TYPE_FIELD],
        id = json[STAMP_ID],
        group = json['group_value'];
  @mustCallSuper
  Map<String, dynamic> toJson() => {
        STAMP_FIELD: stamp,
        TYPE_FIELD: type,
        STAMP_ID: id,
        'group_value': group
      };

  @override
  @mustCallSuper
  List<Object?> get props => [stamp, type, group, id];
}
