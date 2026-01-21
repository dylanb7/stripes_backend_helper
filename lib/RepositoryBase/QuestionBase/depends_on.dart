import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/condition.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_listener.dart';
import 'package:yaml/yaml.dart';

export 'condition.dart';

@immutable
class DependsOn with EquatableMixin {
  final List<ConditionGroup> groups;
  const DependsOn(this.groups);

  factory DependsOn.init() => const DependsOn([]);
  const DependsOn.nothing() : groups = const [];

  DependsOn allOf(List<Condition> conditions) => DependsOn(
      [...groups, ConditionGroup(conditions: conditions, op: GroupOp.all)]);

  DependsOn oneOf(List<Condition> conditions) => DependsOn(
      [...groups, ConditionGroup(conditions: conditions, op: GroupOp.one)]);

  bool eval(QuestionsListener listener) {
    if (groups.isEmpty) return true;

    for (final group in groups) {
      if (!group.evaluateWithListener(listener)) return false;
    }
    return true;
  }

  String toReadableString(String? Function(String qid) promptProvider) {
    if (groups.isEmpty) return 'Always shown';
    final groupStrings =
        groups.map((g) => g.toReadableString(promptProvider)).toList();
    if (groupStrings.length == 1) {
      return groupStrings.first;
    }
    return groupStrings.join(' AND ');
  }

  @override
  String toString() => groups.map((g) => g.serialize()).join('~');

  static DependsOn fromString(String serialized) {
    if (serialized.isEmpty) return const DependsOn.nothing();
    final groups = serialized
        .split('~')
        .map(Condition.fromString)
        .whereType<ConditionGroup>()
        .toList();
    return DependsOn(groups);
  }

  factory DependsOn.fromYaml(YamlMap yamlMap) {
    final Map<String, dynamic> yamlData = Map<String, dynamic>.from(yamlMap);

    // Use the shared parsing logic.
    final condition = Condition.fromYaml(yamlData);

    if (condition == null) return const DependsOn.nothing();

    if (condition is ConditionGroup) {
      return DependsOn([condition]);
    }

    // Wrap single condition
    return DependsOn([
      ConditionGroup(conditions: [condition], op: GroupOp.all)
    ]);
  }

  @override
  List<Object?> get props => groups;
}
