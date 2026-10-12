import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show immutable;

enum EdgeKind {
  dependsOn,
  requires,
  transformSource,
  baselineContext,
}

@immutable
class QuestionEdge with EquatableMixin {
  final String fromId;
  final String toId;
  final EdgeKind kind;

  const QuestionEdge({
    required this.fromId,
    required this.toId,
    required this.kind,
  });

  @override
  List<Object?> get props => [fromId, toId, kind];
}
