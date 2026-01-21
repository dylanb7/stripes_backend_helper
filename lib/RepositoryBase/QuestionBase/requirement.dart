import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/condition.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_listener.dart';
import 'package:yaml/yaml.dart';

export 'condition.dart';

@immutable
class Requirement with EquatableMixin {
  final List<ConditionGroup> groups;
  const Requirement(this.groups);

  factory Requirement.init() => const Requirement([]);
  const Requirement.nothing() : groups = const [];

  factory Requirement.hasEntry() => const Requirement([
        ConditionGroup(conditions: [ExistsCondition()], op: GroupOp.all)
      ]);

  factory Requirement.tryMatch(String pattern) => Requirement([
        ConditionGroup(
            conditions: [MatchesRegex(null, pattern)], op: GroupOp.all)
      ]);

  factory Requirement.exists(String questionId) => Requirement([
        ConditionGroup(
            conditions: [ExistsCondition(questionId)], op: GroupOp.all)
      ]);

  Requirement allOf(List<Condition> conditions) => Requirement(
      [...groups, ConditionGroup(conditions: conditions, op: GroupOp.all)]);

  Requirement oneOf(List<Condition> conditions) => Requirement(
      [...groups, ConditionGroup(conditions: conditions, op: GroupOp.one)]);

  bool eval(QuestionsListener listener, {String? contextId}) {
    if (groups.isEmpty) return true;

    for (final group in groups) {
      if (!group.evaluateWithListener(listener, contextId: contextId)) {
        return false;
      }
    }
    return true;
  }

  String toReadableString(String? Function(String qid) promptProvider) {
    if (groups.isEmpty) return 'No requirements';
    final groupStrings =
        groups.map((g) => g.toReadableString(promptProvider)).toList();
    if (groupStrings.length == 1) {
      return groupStrings.first;
    }
    return groupStrings.join(' AND ');
  }

  @override
  String toString() => groups.map((g) => g.serialize()).join('~');

  static Requirement fromString(String serialized) {
    if (serialized.isEmpty) return const Requirement.nothing();
    final groups = serialized
        .split('~')
        .map(Condition.fromString)
        .whereType<ConditionGroup>()
        .toList();
    return Requirement(groups);
  }

  factory Requirement.fromYaml(YamlMap yamlMap, {String? defaultQuestionId}) {
    final Map<String, dynamic> yamlData = Map<String, dynamic>.from(yamlMap);

    final condition =
        Condition.fromYaml(yamlData, defaultQuestionId: defaultQuestionId);

    if (condition == null) return const Requirement.nothing();

    if (condition is ConditionGroup) {
      return Requirement([condition]);
    }

    return Requirement([
      ConditionGroup(conditions: [condition], op: GroupOp.all)
    ]);
  }

  @override
  List<Object?> get props => groups;
}
