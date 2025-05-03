import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

@immutable
abstract class Question with EquatableMixin {
  final String id;

  final String prompt;

  final String type;

  final bool isRequired, userCreated, isAddition, deleted, enabled, locked;

  const Question(
      {required this.id,
      required this.prompt,
      required this.type,
      required this.isRequired,
      this.enabled = true,
      this.locked = false,
      this.userCreated = false,
      this.isAddition = false,
      this.deleted = false});

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
    if (question is MultipleChoice) return multipleChoice;
    if (question is FreeResponse) return freeResponse;
    if (question is Numeric) return slider;
    if (question is AllThatApply) return allThatApply;
    return check;
  }

  static QuestionType fromId(String id) {
    if (id == "m") return multipleChoice;
    if (id == "f") return freeResponse;
    if (id == "s") return slider;
    if (id == "a") return allThatApply;
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
