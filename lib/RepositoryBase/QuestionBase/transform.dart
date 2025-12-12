import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:yaml/yaml.dart';

const String generatedIdDelimiter = '::';

sealed class Transform with EquatableMixin {
  final String? sourceId;
  const Transform({this.sourceId});

  List<Question> apply(
    Question question,
    List<Response> sourceResponses, {
    int? baselineVersion,
  });

  Map<String, dynamic> toJson();

  String serialize() => jsonEncode(toJson());

  static Transform? fromJson(Map<String, dynamic> json) {
    final type = json[TransformKeys.type] as String?;
    return switch (type) {
      'mapChoices' => MapChoices.fromJson(json),
      'copyValue' => CopyValue.fromJson(json),
      'generateForEach' => GenerateForEach.fromJson(json),
      _ => null,
    };
  }

  static Transform? fromYaml(YamlMap yamlMap) {
    final Map<String, dynamic> data = Map<String, dynamic>.from(yamlMap);
    return fromJson(data);
  }

  static Transform? parse(String? serialized) {
    if (serialized == null) return null;
    try {
      final json = jsonDecode(serialized) as Map<String, dynamic>;
      return fromJson(json);
    } catch (_) {
      return null;
    }
  }
}

@immutable
class MapChoices extends Transform with EquatableMixin {
  const MapChoices({super.sourceId});

  @override
  List<Question> apply(
    Question question,
    List<Response> sourceResponses, {
    int? baselineVersion,
  }) {
    if (question is! MultipleChoice) return [question];

    List<String> newChoices = [];
    for (final targetResponse in sourceResponses) {
      if (targetResponse is OpenResponse) {
        newChoices.add(targetResponse.response);
      } else if (targetResponse is MultiResponse) {
        newChoices.add(targetResponse.choice);
      } else if (targetResponse is AllResponse) {
        newChoices.addAll(targetResponse.choices);
      }
    }
    return [question.copyWith(choices: newChoices)];
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'mapChoices',
        if (sourceId != null) 'sourceId': sourceId,
      };

  static MapChoices fromJson(Map<String, dynamic> json) =>
      MapChoices(sourceId: json[TransformKeys.sourceId] as String?);

  @override
  List<Object?> get props => [sourceId];
}

@immutable
class CopyValue extends Transform with EquatableMixin {
  const CopyValue({super.sourceId});

  @override
  List<Question> apply(
    Question question,
    List<Response> sourceResponses, {
    int? baselineVersion,
  }) {
    final firstResponse = sourceResponses.first;
    String valueToCopy = "";
    switch (firstResponse) {
      case OpenResponse(response: final response):
        valueToCopy = response;
        break;
      case MultiResponse(index: final index, question: final q):
        valueToCopy = q.choices[index];
        break;
      case NumericResponse(response: final response):
        valueToCopy = response.toString();
        break;
      default:
        break;
    }

    final newPrompt =
        question.prompt.replaceAll(RegExp(r'\[value\]'), valueToCopy);
    return [_copyQuestionWithPrompt(question, newPrompt)];
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'copyValue',
        if (sourceId != null) 'sourceId': sourceId,
      };

  static CopyValue fromJson(Map<String, dynamic> json) =>
      CopyValue(sourceId: json[TransformKeys.sourceId] as String?);

  @override
  List<Object?> get props => [sourceId];
}

@immutable
class GenerateForEach extends Transform with EquatableMixin {
  final GeneratedDefinition? generatedDef;

  const GenerateForEach({super.sourceId, this.generatedDef});

  @override
  List<Question> apply(
    Question question,
    List<Response> sourceResponses, {
    int? baselineVersion,
  }) {
    List<Question> generated = [];
    for (final resp in sourceResponses) {
      final List<String> values = _extractValues(resp);
      for (final value in values) {
        String newId =
            '${question.id}$generatedIdDelimiter${sanitizeForId(value)}';
        if (baselineVersion != null) {
          newId = '$newId${generatedIdDelimiter}v$baselineVersion';
        }
        Question newQuestion;
        if (generatedDef != null) {
          newQuestion = generatedDef!.build(question, value, newId);
        } else {
          final newPrompt = question.prompt.replaceAll('{value}', value);
          newQuestion =
              _copyQuestionWithPromptAndId(question, newPrompt, newId);
        }
        generated.add(newQuestion);
      }
    }
    return generated.isEmpty ? [question] : generated;
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'generateForEach',
        if (sourceId != null) 'sourceId': sourceId,
        if (generatedDef != null) 'generated': generatedDef!.toJson(),
      };

  static GenerateForEach fromJson(Map<String, dynamic> json) {
    var generatedMap = json[TransformKeys.generated];
    if (generatedMap is YamlMap) {
      generatedMap = Map<String, dynamic>.from(generatedMap);
    }
    return GenerateForEach(
      sourceId: json[TransformKeys.sourceId] as String?,
      generatedDef: generatedMap != null
          ? GeneratedDefinition.fromJson(generatedMap as Map<String, dynamic>)
          : null,
    );
  }

  @override
  List<Object?> get props => [sourceId, generatedDef];
}

@immutable
class GeneratedDefinition with EquatableMixin {
  final String? prompt;
  final String? questionType;
  final bool isRequired;
  final num? min;
  final num? max;
  final List<String>? choices;

  const GeneratedDefinition({
    this.prompt,
    this.questionType,
    this.isRequired = false,
    this.min,
    this.max,
    this.choices,
  });

  Question build(Question template, String value, String newId) {
    final defPrompt = prompt ?? '{value}';
    final newPrompt = defPrompt.replaceAll('{value}', value);
    final type = questionType ?? template.type;

    return switch (type) {
      'FreeResponse' => FreeResponse(
          id: newId,
          prompt: newPrompt,
          type: template.type,
          userCreated: template.userCreated,
          isRequired: isRequired,
        ),
      'Numeric' => Numeric(
          id: newId,
          prompt: newPrompt,
          type: template.type,
          userCreated: template.userCreated,
          isRequired: isRequired,
          min: min,
          max: max,
        ),
      'Check' => Check(
          id: newId,
          prompt: newPrompt,
          type: template.type,
          userCreated: template.userCreated,
          isRequired: isRequired,
        ),
      'MultipleChoice' => MultipleChoice(
          id: newId,
          prompt: newPrompt,
          type: template.type,
          userCreated: template.userCreated,
          isRequired: isRequired,
          choices: choices ?? [],
        ),
      'AllThatApply' => AllThatApply(
          id: newId,
          prompt: newPrompt,
          type: template.type,
          userCreated: template.userCreated,
          isRequired: isRequired,
          choices: choices ?? [],
        ),
      _ => _copyQuestionWithPromptAndId(template, newPrompt, newId),
    };
  }

  Map<String, dynamic> toJson() => {
        if (prompt != null) 'prompt': prompt,
        if (questionType != null) 'type': questionType,
        'isRequired': isRequired,
        if (min != null) 'min': min,
        if (max != null) 'max': max,
        if (choices != null) 'choices': choices,
      };

  static GeneratedDefinition fromJson(Map<String, dynamic> json) =>
      GeneratedDefinition(
        prompt: json[TransformKeys.prompt] as String?,
        questionType: json[TransformKeys.type] as String?,
        isRequired: json[TransformKeys.isRequired] as bool? ?? false,
        min: json[TransformKeys.min] as num?,
        max: json[TransformKeys.max] as num?,
        choices: json[TransformKeys.choices] != null
            ? List<String>.from(json[TransformKeys.choices])
            : null,
      );

  @override
  List<Object?> get props =>
      [prompt, questionType, isRequired, min, max, choices];
}

// Helper functions

List<String> _extractValues(Response resp) {
  return switch (resp) {
    AllResponse() => resp.choices,
    MultiResponse() => [resp.choice],
    OpenResponse() => [resp.response],
    NumericResponse() => [resp.response.toString()],
    _ => [],
  };
}

Question _copyQuestionWithPrompt(Question question, String newPrompt) {
  return switch (question) {
    FreeResponse() => question.copyWith(prompt: newPrompt),
    Numeric() => question.copyWith(prompt: newPrompt),
    Check() => question.copyWith(prompt: newPrompt),
    MultipleChoice() => question.copyWith(prompt: newPrompt),
    AllThatApply() => question.copyWith(prompt: newPrompt),
  };
}

Question _copyQuestionWithPromptAndId(
    Question question, String newPrompt, String newId) {
  return switch (question) {
    FreeResponse() => question.copyWith(prompt: newPrompt, id: newId),
    Numeric() => question.copyWith(prompt: newPrompt, id: newId),
    Check() => question.copyWith(prompt: newPrompt, id: newId),
    MultipleChoice() => question.copyWith(prompt: newPrompt, id: newId),
    AllThatApply() => question.copyWith(prompt: newPrompt, id: newId),
  };
}

String sanitizeForId(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), '-')
      .replaceAll(RegExp(r'[^a-z0-9\-]'), '');
}

({String templateId, String value, int? baselineVersion})? parseGeneratedId(
    String id) {
  if (!id.contains(generatedIdDelimiter)) return null;
  final parts = id.split(generatedIdDelimiter);

  if (parts.length == 2) {
    return (templateId: parts[0], value: parts[1], baselineVersion: null);
  }

  if (parts.length == 3) {
    final versionStr = parts[2];
    if (!versionStr.startsWith('v')) return null;
    final version = int.tryParse(versionStr.substring(1));
    if (version == null) return null;
    return (templateId: parts[0], value: parts[1], baselineVersion: version);
  }

  return null;
}

List<Response> getSourceResponses(
    Response source, String? sourceId, String? selfId) {
  final targetId = sourceId ?? selfId;
  if (source is ResponseWrap) {
    return source.responses.where((r) => r.question.id == targetId).toList();
  }
  if (source.question.id == targetId) {
    return [source];
  }
  return [];
}

abstract final class TransformKeys {
  static const type = 'type';
  static const sourceId = 'sourceId';
  static const generated = 'generated';
  static const prompt = 'prompt';
  static const isRequired = 'isRequired';
  static const min = 'min';
  static const max = 'max';
  static const choices = 'choices';
}
