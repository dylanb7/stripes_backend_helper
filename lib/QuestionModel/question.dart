import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

@immutable
abstract class Question with EquatableMixin {
  final String id;

  final String prompt;

  final String type;

  const Question({required this.id, required this.prompt, required this.type});

  factory Question.ofType({required String type}) =>
      Check(id: '', prompt: '', type: type);

  static Question empty() => const Check(id: 'empty', prompt: '', type: '');
}

class FreeResponse extends Question {
  const FreeResponse(
      {required String id, required String prompt, required String type})
      : super(id: id, prompt: prompt, type: type);

  @override
  List<Object?> get props => [id, prompt, type];
}

class Numeric extends Question {
  final num? min, max;
  const Numeric(
      {required String id,
      required String prompt,
      required String type,
      this.min,
      this.max})
      : super(id: id, prompt: prompt, type: type);

  @override
  List<Object?> get props => [id, prompt, type, min, max];
}

class Check extends Question {
  const Check(
      {required String id, required String prompt, required String type})
      : super(id: id, prompt: prompt, type: type);

  @override
  List<Object?> get props => [id, prompt, type];
}

class MultipleChoice extends Question {
  final List<String> choices;

  const MultipleChoice(
      {required String id,
      required String prompt,
      required String type,
      required this.choices})
      : super(id: id, prompt: prompt, type: type);

  @override
  List<Object?> get props => [id, prompt, type, choices];
}

class AllThatApply extends Question {
  final List<String> choices;

  const AllThatApply(
      {required String id,
      required String prompt,
      required String type,
      required this.choices})
      : super(id: id, prompt: prompt, type: type);

  @override
  List<Object?> get props => [id, prompt, type, choices];
}
