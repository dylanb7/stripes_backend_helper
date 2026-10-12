import 'package:flutter/foundation.dart' show immutable;
import 'package:stripes_backend_helper/QuestionModel/question.dart';


@immutable
class QuestionSessionState {

  final bool visible;


  final bool valid;
  final bool answered;

  final Question resolvedQuestion;

  const QuestionSessionState({
    required this.visible,
    required this.valid,
    required this.answered,
    required this.resolvedQuestion,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestionSessionState &&
          visible == other.visible &&
          valid == other.valid &&
          answered == other.answered &&
          resolvedQuestion == other.resolvedQuestion;

  @override
  int get hashCode => Object.hash(visible, valid, answered, resolvedQuestion);
}
