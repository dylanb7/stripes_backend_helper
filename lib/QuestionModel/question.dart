import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_repo_base.dart';

@immutable
sealed class Question with EquatableMixin {
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

  final String? fromBaseline;

  final String? transform;

  const Question(
      {required this.id,
      required this.prompt,
      required this.type,
      required this.isRequired,
      this.enabled = true,
      this.locked = false,
      this.userCreated = false,
      this.isAddition = false,
      this.deleted = false,
      this.isBaseline = false,
      this.dependsOn,
      this.fromBaseline,
      this.transform});

  factory Question.ofType({required String type}) =>
      Check(id: '', prompt: '', type: type);

  static Question empty() => const Check(id: 'empty', prompt: '', type: '');
}

class FreeResponse extends Question {
  const FreeResponse(
      {required String id,
      required String prompt,
      required String type,
      super.userCreated,
      super.locked,
      super.isAddition,
      super.deleted,
      super.enabled,
      super.isBaseline,
      super.fromBaseline,
      super.transform,
      super.dependsOn,
      bool? isRequired})
      : super(
            id: id,
            prompt: prompt,
            type: type,
            isRequired: isRequired ?? false);

  @override
  List<Object?> get props => [id, prompt, type, isRequired];
}

class Numeric extends Question {
  final num? min, max;
  const Numeric(
      {required String id,
      required String prompt,
      required String type,
      super.userCreated,
      super.locked,
      super.isAddition,
      super.deleted,
      super.enabled,
      super.isBaseline,
      super.fromBaseline,
      super.transform,
      super.dependsOn,
      bool? isRequired,
      this.min,
      this.max})
      : super(
            id: id,
            prompt: prompt,
            type: type,
            isRequired: isRequired ?? false);

  @override
  List<Object?> get props => [id, prompt, type, min, max, isRequired];
}

class Check extends Question {
  const Check(
      {required String id,
      required String prompt,
      required String type,
      super.isAddition,
      super.locked,
      super.userCreated,
      super.deleted,
      super.enabled,
      super.isBaseline,
      super.fromBaseline,
      super.transform,
      super.dependsOn,
      bool? isRequired})
      : super(
            id: id,
            prompt: prompt,
            type: type,
            isRequired: isRequired ?? false);

  @override
  List<Object?> get props => [id, prompt, type, isRequired];
}

class MultipleChoice extends Question {
  final List<String> choices;

  const MultipleChoice(
      {required String id,
      required String prompt,
      required String type,
      required this.choices,
      super.deleted,
      super.locked,
      super.isAddition,
      super.userCreated,
      super.enabled,
      super.isBaseline,
      super.fromBaseline,
      super.transform,
      super.dependsOn,
      bool? isRequired})
      : super(
            id: id,
            prompt: prompt,
            type: type,
            isRequired: isRequired ?? false);

  @override
  List<Object?> get props => [id, prompt, type, choices, isRequired];
}

class AllThatApply extends Question {
  final List<String> choices;

  const AllThatApply(
      {required String id,
      required String prompt,
      required String type,
      required this.choices,
      super.isAddition,
      super.locked,
      super.deleted,
      super.userCreated,
      super.enabled,
      super.isBaseline,
      super.fromBaseline,
      super.transform,
      super.dependsOn,
      bool? isRequired})
      : super(
            id: id,
            prompt: prompt,
            type: type,
            isRequired: isRequired ?? false);

  @override
  List<Object?> get props => [id, prompt, type, choices, isRequired];
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
    if (value == "MultipleChoice") return multipleChoice;
    if (value == "FreeResponse") return freeResponse;
    if (value == "Numeric") return slider;
    if (value == "AllThatApply") return allThatApply;
    return check;
  }

  static const List<QuestionType> ordered = [
    check,
    freeResponse,
    slider,
    multipleChoice,
    allThatApply
  ];
}
