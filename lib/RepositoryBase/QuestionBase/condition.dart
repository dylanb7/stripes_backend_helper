import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show immutable, listEquals;
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_listener.dart';

sealed class Condition {
  final String? questionId;
  const Condition(this.questionId);

  bool evaluate(Response? response);

  String serialize();

  String toReadableString(String? Function(String qid) promptProvider);

  static Condition? fromYaml(Map<String, dynamic> yaml,
      {String? defaultQuestionId}) {
    if (yaml.containsKey(YamlKeys.oneOf)) {
      final List<dynamic> nested = yaml[YamlKeys.oneOf] as List<dynamic>;
      final conditions = nested
          .map((i) => fromYaml(Map<String, dynamic>.from(i),
              defaultQuestionId: defaultQuestionId))
          .whereType<Condition>()
          .toList();
      if (conditions.isNotEmpty) {
        return ConditionGroup(conditions: conditions, op: GroupOp.one);
      }
      return null;
    }

    if (yaml.containsKey(YamlKeys.allOf)) {
      final List<dynamic> nested = yaml[YamlKeys.allOf] as List<dynamic>;
      final conditions = nested
          .map((i) => fromYaml(Map<String, dynamic>.from(i),
              defaultQuestionId: defaultQuestionId))
          .whereType<Condition>()
          .toList();
      if (conditions.isNotEmpty) {
        return ConditionGroup(conditions: conditions, op: GroupOp.all);
      }
      return null;
    }

    // Explicit ID takes precedence, then default.
    final String? qid =
        (yaml[YamlKeys.questionId] as String?) ?? defaultQuestionId;

    if (yaml.containsKey(YamlKeys.exists)) {
      final val = yaml[YamlKeys.exists];
      if (val is bool && val == true) {
        // If qid is null, it means "self" (which is valid for Requirements)
        return ExistsCondition(qid); // qid can be null
      }
      if (val is String) {
        // "exists: someId" format in yaml? No, usually {exists: true}
        // But code formerly handled {exists: 'someId'} -> ExistsCondition('someId')
        return ExistsCondition(val);
      }
    }

    // For regex, the pattern is the value. Question ID is separate.
    if (yaml.containsKey(YamlKeys.regex)) {
      return MatchesRegex(qid, yaml[YamlKeys.regex] as String);
    }

    if (yaml.containsKey(YamlKeys.equals)) {
      return EqualsExact(qid, yaml[YamlKeys.equals]);
    }

    if (yaml.containsKey(YamlKeys.containsIndex)) {
      return ContainsIndex(qid, yaml[YamlKeys.containsIndex] as int);
    }

    if (yaml.containsKey(YamlKeys.containsText)) {
      return ContainsText(qid, yaml[YamlKeys.containsText] as String);
    }

    return null;
  }

  static Condition? fromString(String serialized) {
    final ConditionGroup? group = ConditionGroup.parse(serialized);
    if (group != null) return group;

    final Condition? exists = ExistsCondition.parse(serialized);
    if (exists != null) return exists;

    final Condition? exact = EqualsExact.parse(serialized);
    if (exact != null) return exact;

    final Condition? cIdx = ContainsIndex.parse(serialized);
    if (cIdx != null) return cIdx;

    final regex = MatchesRegex.parse(serialized);
    if (regex != null) return regex;

    return ContainsText.parse(serialized);
  }
}

@immutable
class ExistsCondition extends Condition with EquatableMixin {
  static const validFor = QuestionType.values;

  const ExistsCondition([super.questionId]);

  @override
  bool evaluate(Response? response) => response != null;

  @override
  String serialize() => 'exists:${questionId ?? ""}';

  static ExistsCondition? parse(String serialized) {
    if (!serialized.startsWith('exists:')) return null;
    final id = serialized.substring(7);
    return ExistsCondition(id.isEmpty ? null : id);
  }

  @override
  String toReadableString(String? Function(String qid) promptProvider) {
    final effectiveId = questionId ?? "This question";
    final prompt = effectiveId == "This question"
        ? effectiveId
        : (promptProvider(effectiveId) ?? effectiveId);
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
    return 'exact:${questionId ?? ""}:$valueStr';
  }

  static EqualsExact? parse(String serialized) {
    if (!serialized.startsWith('exact:')) return null;
    final parts = serialized.split(':');
    if (parts.length < 3) return null;
    final idStr = parts[1];
    final qid = idStr.isEmpty ? null : idStr;
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
    final effectiveId = questionId ?? "This question";
    final prompt = effectiveId == "This question"
        ? effectiveId
        : (promptProvider(effectiveId) ?? effectiveId);
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
  String serialize() => 'cIdx:${questionId ?? ""}:$index';

  static ContainsIndex? parse(String serialized) {
    if (!serialized.startsWith('cIdx:')) return null;
    final parts = serialized.split(':');
    if (parts.length != 3) return null;
    final idStr = parts[1];
    final qid = idStr.isEmpty ? null : idStr;
    final value = int.tryParse(parts[2]);
    if (value == null) return null;
    return ContainsIndex(qid, value);
  }

  @override
  String toReadableString(String? Function(String qid) promptProvider) {
    final effectiveId = questionId ?? "This question";
    final prompt = effectiveId == "This question"
        ? effectiveId
        : (promptProvider(effectiveId) ?? effectiveId);
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
  String serialize() => 'cTxt:${questionId ?? ""}:$text';

  static ContainsText? parse(String serialized) {
    if (!serialized.startsWith('cTxt:')) return null;
    final parts = serialized.split(':');
    if (parts.length < 3) return null;
    final idStr = parts[1];
    final qid = idStr.isEmpty ? null : idStr;
    return ContainsText(qid, parts.sublist(2).join(':'));
  }

  @override
  String toReadableString(String? Function(String qid) promptProvider) {
    final effectiveId = questionId ?? "This question";
    final prompt = effectiveId == "This question"
        ? effectiveId
        : (promptProvider(effectiveId) ?? effectiveId);
    return '"$prompt" contains "$text"';
  }

  @override
  List<Object?> get props => [questionId, text];
}

@immutable
class MatchesRegex extends Condition with EquatableMixin {
  static const validFor = {QuestionType.freeResponse};

  final String pattern;
  const MatchesRegex(super.questionId, this.pattern);

  @override
  bool evaluate(Response? response) {
    if (response is! OpenResponse) return false;
    final regex = RegExp(pattern);
    return regex.hasMatch(response.response);
  }

  @override
  String serialize() => 'regex:${questionId ?? ""}:$pattern';

  static MatchesRegex? parse(String serialized) {
    if (!serialized.startsWith('regex:')) return null;
    final parts = serialized.split(':');
    if (parts.length < 3) return null;
    final idStr = parts[1];
    final qid = idStr.isEmpty ? null : idStr;
    return MatchesRegex(qid, parts.sublist(2).join(':'));
  }

  @override
  String toReadableString(String? Function(String qid) promptProvider) {
    final effectiveId = questionId ?? "This question";
    final prompt = effectiveId == "This question"
        ? effectiveId
        : (promptProvider(effectiveId) ?? effectiveId);
    return '"$prompt" matches pattern "$pattern"';
  }

  @override
  List<Object?> get props => [questionId, pattern];
}

enum GroupOp { all, one }

@immutable
class ConditionGroup extends Condition with EquatableMixin {
  final List<Condition> conditions;
  final GroupOp op;

  const ConditionGroup({
    required this.conditions,
    required this.op,
  }) : super(null); // ConditionGroup doesn't target a single question

  @override
  bool evaluate(Response? response) {
    throw UnsupportedError(
        'ConditionGroup.evaluate(Response?) not supported. Use evaluateWithListener.');
  }

  bool evaluateWithListener(QuestionsListener listener, {String? contextId}) {
    for (final condition in conditions) {
      bool result;
      if (condition is ConditionGroup) {
        result = condition.evaluateWithListener(listener, contextId: contextId);
      } else {
        final targetId = condition.questionId ?? contextId;
        if (targetId == null) {
          // Cannot evaluate condition without target ID in this context
          // Usually means malformed config or "self" used where no "self" exists
          return false;
        }
        final response = listener.questions[targetId];
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
        .map(Condition.fromString)
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

abstract final class YamlKeys {
  static const oneOf = 'oneOf';
  static const allOf = 'allOf';
  static const questionId = 'questionId';
  static const exists = 'exists';
  static const equals = 'equals';
  static const containsIndex = 'containsIndex';
  static const containsText = 'containsText';
  static const regex = 'regex';
}
