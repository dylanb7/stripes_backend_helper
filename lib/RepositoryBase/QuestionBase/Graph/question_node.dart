import 'package:flutter/foundation.dart' show immutable;
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/Graph/question_edge.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/Graph/display_config.dart';

@immutable
class QuestionNode {
  final Question question;

  final List<QuestionEdge> edges;

  final DisplayConfig? displayConfig;

  final EntryConfig? entryConfig;

  const QuestionNode({
    required this.question,
    this.edges = const [],
    this.displayConfig,
    this.entryConfig,
  });

  String get id => question.id;
}
@immutable
class QuestionNodeState {
  final bool enabled;

  /// Whether this question's type currently requires a checkin to be displayed.
  final bool checkinRequired;

  const QuestionNodeState({
    required this.enabled,
    this.checkinRequired = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestionNodeState &&
          enabled == other.enabled &&
          checkinRequired == other.checkinRequired;

  @override
  int get hashCode => Object.hash(enabled, checkinRequired);
}
