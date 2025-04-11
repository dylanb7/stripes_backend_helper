import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

@immutable
abstract class Question with EquatableMixin {
  final String id;

  final String prompt;

  final String type;

  final bool isRequired, userCreated;

  const Question(
      {required this.id,
      required this.prompt,
      required this.type,
      required this.isRequired,
      this.userCreated = false});

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
      super.userCreated,
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
      super.userCreated,
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
      super.userCreated,
      bool? isRequired})
      : super(
            id: id,
            prompt: prompt,
            type: type,
            isRequired: isRequired ?? false);

  @override
  List<Object?> get props => [id, prompt, type, choices, isRequired];
}
