import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show immutable, listEquals;
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_listener.dart';
import 'package:yaml/yaml.dart';

sealed class Condition {
  final String questionId;
  const Condition(this.questionId);

  bool evaluate(Response? response);

  String serialize();

  String toReadableString(String? Function(String qid) promptProvider);
}

@immutable
class ExistsCondition extends Condition with EquatableMixin {
  static const validFor = QuestionType.values;

  const ExistsCondition(super.questionId);

  @override
  bool evaluate(Response? response) => response != null;

  @override
  String serialize() => 'exists:$questionId';

  static ExistsCondition? parse(String serialized) {
    if (!serialized.startsWith('exists:')) return null;
    return ExistsCondition(serialized.substring(7));
  }

  @override
  String toReadableString(String? Function(String qid) promptProvider) {
    final prompt = promptProvider(questionId) ?? questionId;
    return '"$prompt" has a response';
  }

  @override
  List<Object?> get props => [questionId];
}

@immutable
class EqualsExact extends Condition with EquatableMixin {
  static const validFor = {
    QuestionType.slider,
    QuestionType.multipleChoice,
    QuestionType.freeResponse,
    QuestionType.allThatApply,
  };

  final Object expected;
  const EqualsExact(super.questionId, this.expected);

  @override
  bool evaluate(Response? response) {
    if (response == null) return false;
    return switch (response) {
      NumericResponse r => r.response == expected,
      MultiResponse r => r.index == expected,
      OpenResponse r => r.response == expected,
      AllResponse r =>
        expected is List<int> && listEquals(r.responses, expected as List<int>),
      _ => false,
    };
  }

  @override
  String serialize() {
    final valueStr = expected is List<int>
        ? (expected as List<int>).join('|')
        : expected.toString();
    return 'exact:$questionId:$valueStr';
  }

  static EqualsExact? parse(String serialized) {
    if (!serialized.startsWith('exact:')) return null;
    final parts = serialized.split(':');
    if (parts.length < 3) return null;
    final qid = parts[1];
    final valueStr = parts.sublist(2).join(':');

    // Try parsing as int list first
    if (valueStr.contains('|')) {
      final indices =
          valueStr.split('|').map(int.tryParse).whereType<int>().toList();
      return EqualsExact(qid, indices);
    }
    // Try as num
    final numVal = num.tryParse(valueStr);
    if (numVal != null) return EqualsExact(qid, numVal);
    // Fall back to string
    return EqualsExact(qid, valueStr);
  }

  @override
  String toReadableString(String? Function(String qid) promptProvider) {
    final prompt = promptProvider(questionId) ?? questionId;
    final valueStr = expected is List<int>
        ? (expected as List<int>).join(', ')
        : expected.toString();
    return '"$prompt" equals $valueStr';
  }

  @override
  List<Object?> get props => [questionId, expected];
}

@immutable
class ContainsIndex extends Condition with EquatableMixin {
  static const validFor = {QuestionType.allThatApply};

  final int index;
  const ContainsIndex(super.questionId, this.index);

  @override
  bool evaluate(Response? response) {
    if (response is! AllResponse) return false;
    return response.responses.contains(index);
  }

  @override
  String serialize() => 'cIdx:$questionId:$index';

  static ContainsIndex? parse(String serialized) {
    if (!serialized.startsWith('cIdx:')) return null;
    final parts = serialized.split(':');
    if (parts.length != 3) return null;
    final value = int.tryParse(parts[2]);
    if (value == null) return null;
    return ContainsIndex(parts[1], value);
  }

  @override
  String toReadableString(String? Function(String qid) promptProvider) {
    final prompt = promptProvider(questionId) ?? questionId;
    return '"$prompt" contains index $index';
  }

  @override
  List<Object?> get props => [questionId, index];
}

@immutable
class ContainsText extends Condition with EquatableMixin {
  static const validFor = {QuestionType.freeResponse};

  final String text;
  const ContainsText(super.questionId, this.text);

  @override
  bool evaluate(Response? response) {
    if (response is! OpenResponse) return false;
    return response.response.contains(text);
  }

  @override
  String serialize() => 'cTxt:$questionId:$text';

  static ContainsText? parse(String serialized) {
    if (!serialized.startsWith('cTxt:')) return null;
    final parts = serialized.split(':');
    if (parts.length < 3) return null;
    return ContainsText(parts[1], parts.sublist(2).join(':'));
  }

  @override
  String toReadableString(String? Function(String qid) promptProvider) {
    final prompt = promptProvider(questionId) ?? questionId;
    return '"$prompt" contains "$text"';
  }

  @override
  List<Object?> get props => [questionId, text];
}

Condition? parseCondition(String serialized) {
  final ConditionGroup? group = ConditionGroup.parse(serialized);
  if (group != null) return group;
  final Condition? exists = ExistsCondition.parse(serialized);
  if (exists != null) return exists;

  final Condition? exact = EqualsExact.parse(serialized);
  if (exact != null) return exact;

  final Condition? cIdx = ContainsIndex.parse(serialized);
  if (cIdx != null) return cIdx;

  return ContainsText.parse(serialized);
}

enum GroupOp { all, one }

@immutable
class ConditionGroup extends Condition with EquatableMixin {
  final List<Condition> conditions;
  final GroupOp op;

  const ConditionGroup({
    required this.conditions,
    required this.op,
  }) : super('');

  @override
  bool evaluate(Response? response) {
    throw UnsupportedError(
        'ConditionGroup.evaluate(Response?) not supported. Use evaluateWithListener.');
  }

  bool evaluateWithListener(QuestionsListener listener) {
    for (final condition in conditions) {
      bool result;
      if (condition is ConditionGroup) {
        result = condition.evaluateWithListener(listener);
      } else {
        final response = listener.questions[condition.questionId];
        result = condition.evaluate(response);
      }

      if (op == GroupOp.all && !result) return false;
      if (op == GroupOp.one && result) return true;
    }

    return op == GroupOp.all;
  }

  @override
  String serialize() {
    final condStr = conditions.map((c) => c.serialize()).join('&');
    return '($condStr)${op.name}';
  }

  static ConditionGroup? parse(String serialized) {
    // Format: (cond1&cond2&...)all or (cond1&cond2&...)one
    if (!serialized.startsWith('(')) return null;

    final lastParen = serialized.lastIndexOf(')');
    if (lastParen == -1) return null;

    final opStr = serialized.substring(lastParen + 1);
    final op = opStr == 'all'
        ? GroupOp.all
        : opStr == 'one'
            ? GroupOp.one
            : null;
    if (op == null) return null;

    final innerStr = serialized.substring(1, lastParen);
    final conditions = _splitConditions(innerStr)
        .map(parseCondition)
        .whereType<Condition>()
        .toList();

    return ConditionGroup(conditions: conditions, op: op);
  }

  static List<String> _splitConditions(String inner) {
    final result = <String>[];
    var depth = 0;
    var current = StringBuffer();

    for (var i = 0; i < inner.length; i++) {
      final char = inner[i];
      if (char == '(') depth++;
      if (char == ')') depth--;

      if (char == '&' && depth == 0) {
        result.add(current.toString());
        current = StringBuffer();
      } else {
        current.write(char);
      }
    }
    if (current.isNotEmpty) {
      result.add(current.toString());
    }
    return result;
  }

  @override
  String toReadableString(String? Function(String qid) promptProvider) {
    final opWord = op == GroupOp.all ? 'ALL of' : 'ONE of';
    final conditionStrings =
        conditions.map((c) => c.toReadableString(promptProvider)).toList();
    if (conditionStrings.length == 1) {
      return conditionStrings.first;
    }
    return '($opWord: ${conditionStrings.join(', ')})';
  }

  @override
  List<Object?> get props => [...conditions, op];
}

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
        .map(ConditionGroup.parse)
        .whereType<ConditionGroup>()
        .toList();
    return DependsOn(groups);
  }

  factory DependsOn.fromYaml(YamlMap yamlMap) {
    final Map<String, dynamic> yamlData = Map<String, dynamic>.from(yamlMap);
    DependsOn dependsOn = const DependsOn.nothing();
    Condition? parseConditionFromYaml(Map<String, dynamic> item) {
      if (item.containsKey(YamlKeys.oneOf)) {
        final List<dynamic> nested = item[YamlKeys.oneOf] as List<dynamic>;
        final conditions = nested
            .map((i) => parseConditionFromYaml(Map<String, dynamic>.from(i)))
            .whereType<Condition>()
            .toList();
        if (conditions.isNotEmpty) {
          return ConditionGroup(conditions: conditions, op: GroupOp.one);
        }
        return null;
      }

      // Check for nested allOf (becomes ConditionGroup)
      if (item.containsKey(YamlKeys.allOf)) {
        final List<dynamic> nested = item[YamlKeys.allOf] as List<dynamic>;
        final conditions = nested
            .map((i) => parseConditionFromYaml(Map<String, dynamic>.from(i)))
            .whereType<Condition>()
            .toList();
        if (conditions.isNotEmpty) {
          return ConditionGroup(conditions: conditions, op: GroupOp.all);
        }
        return null;
      }

      // exists: questionId
      if (item.containsKey(YamlKeys.exists)) {
        return ExistsCondition(item[YamlKeys.exists] as String);
      }

      // All other conditions require questionId
      if (!item.containsKey(YamlKeys.questionId)) return null;
      final String qid = item[YamlKeys.questionId] as String;

      // equals: value (works with any response type)
      if (item.containsKey(YamlKeys.equals)) {
        final value = item[YamlKeys.equals];
        if (value is List) {
          final indices = value
              .map((e) => e is int ? e : int.tryParse(e.toString()))
              .whereType<int>()
              .toList();
          return EqualsExact(qid, indices);
        }
        return EqualsExact(qid, value);
      }

      // containsIndex: value (for AllThatApply)
      if (item.containsKey(YamlKeys.containsIndex)) {
        final value = item[YamlKeys.containsIndex];
        final index = value is int ? value : int.tryParse(value.toString());
        if (index != null) {
          return ContainsIndex(qid, index);
        }
      }

      // containsText: value (for FreeResponse)
      if (item.containsKey(YamlKeys.containsText)) {
        final value = item[YamlKeys.containsText];
        if (value is String) {
          return ContainsText(qid, value);
        }
      }

      return null;
    }

    // Parse top-level oneOf
    if (yamlData.containsKey(YamlKeys.oneOf)) {
      final List<dynamic> items = yamlData[YamlKeys.oneOf] as List<dynamic>;
      final conditions = items
          .map(
              (item) => parseConditionFromYaml(Map<String, dynamic>.from(item)))
          .whereType<Condition>()
          .toList();
      if (conditions.isNotEmpty) {
        dependsOn = dependsOn.oneOf(conditions);
      }
    }

    // Parse top-level allOf
    if (yamlData.containsKey(YamlKeys.allOf)) {
      final List<dynamic> items = yamlData[YamlKeys.allOf] as List<dynamic>;
      final conditions = items
          .map(
              (item) => parseConditionFromYaml(Map<String, dynamic>.from(item)))
          .whereType<Condition>()
          .toList();
      if (conditions.isNotEmpty) {
        dependsOn = dependsOn.allOf(conditions);
      }
    }

    if (dependsOn.groups.isEmpty) {
      final condition = parseConditionFromYaml(yamlData);
      if (condition != null) {
        dependsOn = dependsOn.allOf([condition]);
      }
    }

    return dependsOn;
  }

  @override
  List<Object?> get props => groups;
}

abstract final class YamlKeys {
  static const oneOf = 'oneOf';
  static const allOf = 'allOf';
  static const questionId = 'questionId';
  static const exists = 'exists';
  static const equals = 'equals';
  static const containsIndex = 'containsIndex';
  static const containsText = 'containsText';
}
