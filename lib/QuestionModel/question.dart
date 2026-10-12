import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_repo_base.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/requirement.dart';

@immutable
sealed class Question with Equatable {
  final String id;

  final String prompt;

  final String type;

  final bool isRequired,
      userCreated,
      isAddition,
      deleted,
      enabled,
      locked,
      isBaseline;

  final DependsOn? dependsOn;

  final Requirement? requirement;

  final String? fromBaseline;

  final String? transform;

  final Map<String, String>? interpolations;

  /// Baseline question IDs whose previous answers should be shown as
  /// contextual reference when presenting this question in the UI.
  final List<String>? baselineContext;

  const Question({
    required this.id,
    required this.prompt,
    required this.type,
    this.enabled = true,
    this.locked = false,
    this.userCreated = false,
    this.isAddition = false,
    this.deleted = false,
    this.isBaseline = false,
    this.isRequired = false,
    this.dependsOn,
    this.requirement,
    this.fromBaseline,
    this.transform,
    this.interpolations,
    this.baselineContext,
  });

  factory Question.ofType({required String type}) =>
      Check(id: '', prompt: '', type: type);

  static Question empty() => const Check(id: 'empty', prompt: '', type: '');

  Map<String, dynamic> toJson() => {
    'id': id,
    'prompt': prompt,
    'type': type,
    'isRequired': isRequired ? 1 : 0,
    'userCreated': userCreated ? 1 : 0,
    'isAddition': isAddition ? 1 : 0,
    'deleted': deleted ? 1 : 0,
    'enabled': enabled ? 1 : 0,
    'isBaseline': isBaseline ? 1 : 0,
    'fromBaseline': fromBaseline,
    'transform': transform,
    'interpolations': interpolations != null
        ? jsonEncode(interpolations)
        : null,
    'baselineContext': baselineContext != null
        ? jsonEncode(baselineContext)
        : null,
    'questionType': QuestionType.from(this).id,
    'dependsOn': dependsOn?.toString(),
    'requirement': requirement?.toString(),
  };

  factory Question.fromJson(Map<String, dynamic> json) {
    final questionType = json['questionType'];
    switch (QuestionType.fromId(questionType)) {
      case QuestionType.freeResponse:
        return FreeResponse.fromJson(json);
      case QuestionType.slider:
        return Numeric.fromJson(json);
      case QuestionType.check:
        return Check.fromJson(json);
      case QuestionType.multipleChoice:
        return MultipleChoice.fromJson(json);
      case QuestionType.allThatApply:
        return AllThatApply.fromJson(json);
    }
  }

  static Map<String, String>? parseInterpolations(dynamic value) {
    if (value == null) return null;
    if (value is Map) return Map<String, String>.from(value);
    if (value is String) {
      try {
        return Map<String, String>.from(jsonDecode(value) as Map);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static List<String>? parseBaselineContext(dynamic value) {
    if (value == null) return null;
    if (value is List) return List<String>.from(value);
    if (value is String) {
      try {
        return List<String>.from(jsonDecode(value) as List);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  @override
  List<Object?> get props => [
    id,
    prompt,
    type,
    isRequired,
    deleted,
    userCreated,
    isBaseline,
    fromBaseline,
    transform,
    interpolations,
    baselineContext,
    dependsOn,
    requirement,
  ];
}

class FreeResponse extends Question {
  const FreeResponse({
    required super.id,
    required super.prompt,
    required super.type,
    super.userCreated,
    super.locked,
    super.isAddition,
    super.deleted,
    super.enabled,
    super.isBaseline,
    super.fromBaseline,
    super.transform,
    super.interpolations,
    super.baselineContext,
    super.dependsOn,
    super.requirement,
    bool? isRequired,
  }) : super(isRequired: isRequired ?? false);

  factory FreeResponse.fromJson(Map<String, dynamic> json) {
    return FreeResponse(
      id: json['id'],
      prompt: json['prompt'],
      type: json['type'],
      isRequired: json['isRequired'] == 1,
      userCreated: json['userCreated'] == 1,
      isAddition: json['isAddition'] == 1,
      deleted: json['deleted'] == 1,
      enabled: json['enabled'] == 1,
      isBaseline: json['isBaseline'] == 1,
      fromBaseline: json['fromBaseline'],
      transform: json['transform'],
      interpolations: Question.parseInterpolations(json['interpolations']),
      baselineContext: Question.parseBaselineContext(json['baselineContext']),
      dependsOn: json["dependsOn"] == null
          ? const DependsOn.nothing()
          : DependsOn.fromString(json["dependsOn"]),
      requirement: json["requirement"] == null
          ? const Requirement.nothing()
          : Requirement.fromString(json["requirement"]),
    );
  }

  FreeResponse copyWith({
    String? id,
    String? prompt,
    String? type,
    bool? userCreated,
    bool? locked,
    bool? isAddition,
    bool? deleted,
    bool? enabled,
    bool? isBaseline,
    String? fromBaseline,
    String? transform,
    Map<String, String>? interpolations,
    List<String>? baselineContext,
    DependsOn? dependsOn,
    Requirement? requirement,
    bool? isRequired,
  }) {
    return FreeResponse(
      id: id ?? this.id,
      prompt: prompt ?? this.prompt,
      type: type ?? this.type,
      userCreated: userCreated ?? this.userCreated,
      locked: locked ?? this.locked,
      isAddition: isAddition ?? this.isAddition,
      deleted: deleted ?? this.deleted,
      enabled: enabled ?? this.enabled,
      isBaseline: isBaseline ?? this.isBaseline,
      fromBaseline: fromBaseline ?? this.fromBaseline,
      transform: transform ?? this.transform,
      interpolations: interpolations ?? this.interpolations,
      baselineContext: baselineContext ?? this.baselineContext,
      dependsOn: dependsOn ?? this.dependsOn,
      requirement: requirement ?? this.requirement,
      isRequired: isRequired ?? this.isRequired,
    );
  }
}

class Numeric extends Question {
  final num? min, max;
  const Numeric({
    required super.id,
    required super.prompt,
    required super.type,
    super.userCreated,
    super.locked,
    super.isAddition,
    super.deleted,
    super.enabled,
    super.isBaseline,
    super.fromBaseline,
    super.transform,
    super.interpolations,
    super.baselineContext,
    super.dependsOn,
    super.requirement,
    bool? isRequired,
    this.min,
    this.max,
  }) : super(isRequired: isRequired ?? false);

  factory Numeric.fromJson(Map<String, dynamic> json) {
    return Numeric(
      id: json['id'],
      prompt: json['prompt'],
      type: json['type'],
      min: json['min'],
      max: json['max'],
      isRequired: json['isRequired'] == 1,
      userCreated: json['userCreated'] == 1,
      isAddition: json['isAddition'] == 1,
      deleted: json['deleted'] == 1,
      enabled: json['enabled'] == 1,
      isBaseline: json['isBaseline'] == 1,
      fromBaseline: json['fromBaseline'],
      transform: json['transform'],
      interpolations: Question.parseInterpolations(json['interpolations']),
      baselineContext: Question.parseBaselineContext(json['baselineContext']),
      dependsOn: json["dependsOn"] == null
          ? const DependsOn.nothing()
          : DependsOn.fromString(json["dependsOn"]),
      requirement: json["requirement"] == null
          ? const Requirement.nothing()
          : Requirement.fromString(json["requirement"]),
    );
  }

  @override
  List<Object?> get props => [...super.props, min, max];

  Numeric copyWith({
    String? id,
    String? prompt,
    String? type,
    bool? userCreated,
    bool? locked,
    bool? isAddition,
    bool? deleted,
    bool? enabled,
    bool? isBaseline,
    String? fromBaseline,
    String? transform,
    Map<String, String>? interpolations,
    List<String>? baselineContext,
    DependsOn? dependsOn,
    Requirement? requirement,
    bool? isRequired,
    num? min,
    num? max,
  }) {
    return Numeric(
      id: id ?? this.id,
      prompt: prompt ?? this.prompt,
      type: type ?? this.type,
      userCreated: userCreated ?? this.userCreated,
      locked: locked ?? this.locked,
      isAddition: isAddition ?? this.isAddition,
      deleted: deleted ?? this.deleted,
      enabled: enabled ?? this.enabled,
      isBaseline: isBaseline ?? this.isBaseline,
      fromBaseline: fromBaseline ?? this.fromBaseline,
      transform: transform ?? this.transform,
      interpolations: interpolations ?? this.interpolations,
      baselineContext: baselineContext ?? this.baselineContext,
      dependsOn: dependsOn ?? this.dependsOn,
      requirement: requirement ?? this.requirement,
      isRequired: isRequired ?? this.isRequired,
      min: min ?? this.min,
      max: max ?? this.max,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['min'] = min;
    json['max'] = max;
    return json;
  }
}

class Check extends Question {
  const Check({
    required super.id,
    required super.prompt,
    required super.type,
    super.isAddition,
    super.locked,
    super.userCreated,
    super.deleted,
    super.enabled,
    super.isBaseline,
    super.fromBaseline,
    super.transform,
    super.interpolations,
    super.baselineContext,
    super.dependsOn,
    super.requirement,
    bool? isRequired,
  }) : super(isRequired: isRequired ?? false);

  factory Check.fromJson(Map<String, dynamic> json) {
    return Check(
      id: json['id'],
      prompt: json['prompt'],
      type: json['type'],
      isRequired: json['isRequired'] == 1,
      userCreated: json['userCreated'] == 1,
      isAddition: json['isAddition'] == 1,
      deleted: json['deleted'] == 1,
      enabled: json['enabled'] == 1,
      isBaseline: json['isBaseline'] == 1,
      fromBaseline: json['fromBaseline'],
      transform: json['transform'],
      interpolations: Question.parseInterpolations(json['interpolations']),
      baselineContext: Question.parseBaselineContext(json['baselineContext']),
      dependsOn: json["dependsOn"] == null
          ? const DependsOn.nothing()
          : DependsOn.fromString(json["dependsOn"]),
      requirement: json["requirement"] == null
          ? const Requirement.nothing()
          : Requirement.fromString(json["requirement"]),
    );
  }

  Check copyWith({
    String? id,
    String? prompt,
    String? type,
    bool? isAddition,
    bool? locked,
    bool? userCreated,
    bool? deleted,
    bool? enabled,
    bool? isBaseline,
    String? fromBaseline,
    String? transform,
    Map<String, String>? interpolations,
    List<String>? baselineContext,
    DependsOn? dependsOn,
    Requirement? requirement,
    bool? isRequired,
  }) {
    return Check(
      id: id ?? this.id,
      prompt: prompt ?? this.prompt,
      type: type ?? this.type,
      isAddition: isAddition ?? this.isAddition,
      locked: locked ?? this.locked,
      userCreated: userCreated ?? this.userCreated,
      deleted: deleted ?? this.deleted,
      enabled: enabled ?? this.enabled,
      isBaseline: isBaseline ?? this.isBaseline,
      fromBaseline: fromBaseline ?? this.fromBaseline,
      transform: transform ?? this.transform,
      interpolations: interpolations ?? this.interpolations,
      baselineContext: baselineContext ?? this.baselineContext,
      dependsOn: dependsOn ?? this.dependsOn,
      requirement: requirement ?? this.requirement,
      isRequired: isRequired ?? this.isRequired,
    );
  }
}

class MultipleChoice extends Question {
  final List<String> choices;

  const MultipleChoice({
    required super.id,
    required super.prompt,
    required super.type,
    required this.choices,
    super.deleted,
    super.locked,
    super.isAddition,
    super.userCreated,
    super.enabled,
    super.isBaseline,
    super.fromBaseline,
    super.transform,
    super.interpolations,
    super.baselineContext,
    super.dependsOn,
    super.requirement,
    bool? isRequired,
  }) : super(isRequired: isRequired ?? false);

  factory MultipleChoice.fromJson(Map<String, dynamic> json) {
    return MultipleChoice(
      id: json['id'],
      prompt: json['prompt'],
      type: json['type'],
      choices: json['choices'] is String
          ? (json['choices'] as String).split(',')
          : [],
      isRequired: json['isRequired'] == 1,
      userCreated: json['userCreated'] == 1,
      isAddition: json['isAddition'] == 1,
      deleted: json['deleted'] == 1,
      enabled: json['enabled'] == 1,
      isBaseline: json['isBaseline'] == 1,
      fromBaseline: json['fromBaseline'],
      transform: json['transform'],
      interpolations: Question.parseInterpolations(json['interpolations']),
      baselineContext: Question.parseBaselineContext(json['baselineContext']),
      dependsOn: json["dependsOn"] == null
          ? const DependsOn.nothing()
          : DependsOn.fromString(json["dependsOn"]),
      requirement: json["requirement"] == null
          ? const Requirement.nothing()
          : Requirement.fromString(json["requirement"]),
    );
  }

  @override
  List<Object?> get props => [...super.props, choices];

  MultipleChoice copyWith({
    String? id,
    String? prompt,
    String? type,
    List<String>? choices,
    bool? deleted,
    bool? locked,
    bool? isAddition,
    bool? userCreated,
    bool? enabled,
    bool? isBaseline,
    String? fromBaseline,
    String? transform,
    Map<String, String>? interpolations,
    List<String>? baselineContext,
    DependsOn? dependsOn,
    Requirement? requirement,
    bool? isRequired,
  }) {
    return MultipleChoice(
      id: id ?? this.id,
      prompt: prompt ?? this.prompt,
      type: type ?? this.type,
      choices: choices ?? this.choices,
      deleted: deleted ?? this.deleted,
      locked: locked ?? this.locked,
      isAddition: isAddition ?? this.isAddition,
      userCreated: userCreated ?? this.userCreated,
      enabled: enabled ?? this.enabled,
      isBaseline: isBaseline ?? this.isBaseline,
      fromBaseline: fromBaseline ?? this.fromBaseline,
      transform: transform ?? this.transform,
      interpolations: interpolations ?? this.interpolations,
      baselineContext: baselineContext ?? this.baselineContext,
      dependsOn: dependsOn ?? this.dependsOn,
      requirement: requirement ?? this.requirement,
      isRequired: isRequired ?? this.isRequired,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['choices'] = choices.join(',');
    return json;
  }
}

class AllThatApply extends Question {
  final List<String> choices;

  const AllThatApply({
    required super.id,
    required super.prompt,
    required super.type,
    required this.choices,
    super.isAddition,
    super.locked,
    super.deleted,
    super.userCreated,
    super.enabled,
    super.isBaseline,
    super.fromBaseline,
    super.transform,
    super.interpolations,
    super.baselineContext,
    super.dependsOn,
    super.requirement,
    bool? isRequired,
  }) : super(isRequired: isRequired ?? false);

  factory AllThatApply.fromJson(Map<String, dynamic> json) {
    return AllThatApply(
      id: json['id'],
      prompt: json['prompt'],
      type: json['type'],
      isRequired: json['isRequired'] == 1,
      choices: json['choices'] is String
          ? (json['choices'] as String).split(',')
          : [],
      userCreated: json['userCreated'] == 1,
      isAddition: json['isAddition'] == 1,
      deleted: json['deleted'] == 1,
      enabled: json['enabled'] == 1,
      isBaseline: json['isBaseline'] == 1,
      fromBaseline: json['fromBaseline'],
      transform: json['transform'],
      interpolations: Question.parseInterpolations(json['interpolations']),
      baselineContext: Question.parseBaselineContext(json['baselineContext']),
      dependsOn: json["dependsOn"] == null
          ? const DependsOn.nothing()
          : DependsOn.fromString(json["dependsOn"]),
      requirement: json["requirement"] == null
          ? const Requirement.nothing()
          : Requirement.fromString(json["requirement"]),
    );
  }

  @override
  List<Object?> get props => [...super.props, choices];

  AllThatApply copyWith({
    String? id,
    String? prompt,
    String? type,
    List<String>? choices,
    bool? isAddition,
    bool? locked,
    bool? deleted,
    bool? userCreated,
    bool? enabled,
    bool? isBaseline,
    String? fromBaseline,
    String? transform,
    Map<String, String>? interpolations,
    List<String>? baselineContext,
    DependsOn? dependsOn,
    Requirement? requirement,
    bool? isRequired,
  }) {
    return AllThatApply(
      id: id ?? this.id,
      prompt: prompt ?? this.prompt,
      type: type ?? this.type,
      choices: choices ?? this.choices,
      isAddition: isAddition ?? this.isAddition,
      locked: locked ?? this.locked,
      deleted: deleted ?? this.deleted,
      userCreated: userCreated ?? this.userCreated,
      enabled: enabled ?? this.enabled,
      isBaseline: isBaseline ?? this.isBaseline,
      fromBaseline: fromBaseline ?? this.fromBaseline,
      transform: transform ?? this.transform,
      interpolations: interpolations ?? this.interpolations,
      baselineContext: baselineContext ?? this.baselineContext,
      dependsOn: dependsOn ?? this.dependsOn,
      requirement: requirement ?? this.requirement,
      isRequired: isRequired ?? this.isRequired,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['choices'] = choices.join(',');
    return json;
  }
}

enum QuestionType {
  check("c", "Check"),
  freeResponse("f", "Free Response"),
  slider("s", "Slider"),
  multipleChoice("m", "Multiple Choice"),
  allThatApply("a", "All That Apply");

  final String id, value;

  const QuestionType(this.id, this.value);

  static QuestionType from(Question question) {
    switch (question) {
      case FreeResponse():
        return freeResponse;
      case Numeric():
        return slider;
      case Check():
        return check;
      case MultipleChoice():
        return multipleChoice;
      case AllThatApply():
        return allThatApply;
    }
  }

  static QuestionType fromId(String id) {
    if (id == "m") return multipleChoice;
    if (id == "f") return freeResponse;
    if (id == "s") return slider;
    if (id == "a") return allThatApply;
    return check;
  }

  static QuestionType fromString(String value) {
    if (value == "MultipleChoice" || value == "Multiple Choice") {
      return multipleChoice;
    }
    if (value == "FreeResponse" || value == "Free Response") {
      return freeResponse;
    }
    if (value == "Slider" || value == "Numeric") {
      return slider;
    }
    if (value == "AllThatApply" || value == "All That Apply") {
      return allThatApply;
    }
    return check;
  }

  static const List<QuestionType> ordered = [
    check,
    freeResponse,
    slider,
    multipleChoice,
    allThatApply,
  ];
}
