import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_repo_base.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_resolver.dart';
import 'package:stripes_backend_helper/db_keys.dart';

import '../RepositoryBase/StampBase/stamp.dart';

@immutable
sealed class Response<E extends Question> extends Stamp with EquatableMixin {
  final E question;

  Response(
      {required this.question, required super.stamp, super.id, super.group})
      : super(type: question.type);

  Response.fromJson(Map<String, dynamic> json, QuestionHome home)
      : question = parseQuestion(json[ID_FIELD], home) as E,
        super.fromJson(json);

  static Question parseQuestion(dynamic idField, QuestionHome home) {
    if (idField is String && idField.startsWith('{')) {
      try {
        final questionJson = jsonDecode(idField) as Map<String, dynamic>;
        return Question.fromJson(questionJson);
      } catch (_) {}
    }

    return home.forDisplay(idField) ?? Question.empty();
  }

  Response encodeGeneratedQuestion() {
    if (!_isGeneratedQuestion) return this;

    final String jsonValues = jsonEncode(question.toJson());
    Question newQ;

    switch (question) {
      case FreeResponse q:
        newQ = q.copyWith(id: jsonValues);
      case Numeric q:
        newQ = q.copyWith(id: jsonValues);
      case Check q:
        newQ = q.copyWith(id: jsonValues);
      case MultipleChoice q:
        newQ = q.copyWith(id: jsonValues);
      case AllThatApply q:
        newQ = q.copyWith(id: jsonValues);
    }

    final Response res = this;
    switch (res) {
      case OpenResponse r:
        return OpenResponse(
            question: newQ as FreeResponse,
            response: r.response,
            stamp: r.stamp,
            id: r.id);
      case NumericResponse r:
        return NumericResponse(
            question: newQ as Numeric,
            response: r.response,
            stamp: r.stamp,
            id: r.id);
      case Selected r:
        return Selected(
            question: newQ as Check, stamp: r.stamp, id: r.id, group: r.group);
      case AllResponse r:
        return AllResponse(
            question: newQ as AllThatApply,
            responses: r.responses,
            stamp: r.stamp,
            id: r.id,
            group: r.group);
      case MultiResponse r:
        if (newQ is MultipleChoice) {
          return MultiResponse(
              question: newQ,
              index: r.index,
              stamp: r.stamp,
              id: r.id,
              group: r.group);
        }
        return res;
      default:
        return res;
    }
  }

  bool get _isGeneratedQuestion => question.id.contains(generatedIdDelimiter);

  @override
  Map<String, dynamic> toJson() {
    if (_isGeneratedQuestion) {
      return {...super.toJson(), ID_FIELD: jsonEncode(question.toJson())};
    }
    return {...super.toJson(), ID_FIELD: question.id};
  }
}

class OpenResponse extends Response<FreeResponse> {
  final String response;

  OpenResponse(
      {required FreeResponse question,
      required super.stamp,
      required this.response,
      super.group,
      super.id})
      : super(question: question);

  OpenResponse.fromJson(Map<String, dynamic> json, QuestionHome home)
      : response = json[RESPONSE_FIELD],
        super.fromJson(json, home);

  @override
  Map<String, dynamic> toJson() =>
      {...super.toJson(), RESPONSE_FIELD: response};

  @override
  List<Object?> get props => [
        ...super.props,
        response,
        question,
      ];
}

class NumericResponse extends Response<Numeric> {
  final num response;
  NumericResponse(
      {required Numeric question,
      required int stamp,
      required this.response,
      super.group,
      super.id})
      : super(question: question, stamp: stamp);

  NumericResponse.fromJson(Map<String, dynamic> json, QuestionHome home)
      : response = json[NUMERIC_RESPONSE_FIELD],
        super.fromJson(json, home);

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        NUMERIC_RESPONSE_FIELD: response,
      };

  @override
  List<Object?> get props => [
        ...super.props,
        response,
        question,
      ];
}

class Selected extends Response<Check> {
  Selected({required Check question, required int stamp, super.id, super.group})
      : super(question: question, stamp: stamp);

  Selected.fromJson(Map<String, dynamic> json, QuestionHome home)
      : super.fromJson(json, home);

  @override
  Map<String, dynamic> toJson() => super.toJson();

  @override
  List<Object?> get props => [
        ...super.props,
        question,
      ];
}

class MultiResponse extends Response<MultipleChoice> {
  final int index;

  MultiResponse(
      {required MultipleChoice question,
      required int stamp,
      required this.index,
      super.group,
      super.id})
      : super(question: question, stamp: stamp);

  MultiResponse.fromJson(Map<String, dynamic> json, QuestionHome home)
      : index = json[SELECTED_FIELD],
        super.fromJson(json, home);

  @override
  Map<String, dynamic> toJson() => {...super.toJson(), SELECTED_FIELD: index};

  String get choice => question.choices[index];

  @override
  List<Object?> get props => [...super.props, index, question];
}

class AllResponse extends Response<AllThatApply> {
  final List<int> responses;

  AllResponse(
      {required AllThatApply question,
      required int stamp,
      required this.responses,
      super.group,
      super.id})
      : super(question: question, stamp: stamp);

  AllResponse.fromJson(Map<String, dynamic> json, QuestionHome home)
      : responses = json[SELECTED_FIELDS],
        super.fromJson(json, home);

  @override
  Map<String, dynamic> toJson() =>
      {...super.toJson(), SELECTED_FIELDS: responses};

  List<String> get choices =>
      responses.map((res) => question.choices[res]).toList();

  @override
  List<Object?> get props => [...super.props, responses, question];
}

abstract class ResponseWrap extends Response {
  final List<Response> responses;

  ResponseWrap({
    required this.responses,
    required super.stamp,
    required String type,
    super.group,
    super.id,
  }) : super(question: Question.ofType(type: type));
}

abstract class SingleResponseWrap<E extends Response> extends Response {
  final E response;

  SingleResponseWrap({required this.response, super.group, super.id})
      : super(question: response.question, stamp: response.stamp);
}

class DetailResponse extends ResponseWrap {
  final String? description;

  final String? linkingId;
  DetailResponse(
      {this.description,
      this.linkingId,
      required super.responses,
      super.group,
      super.id,
      required super.stamp,
      String? detailType})
      : super(
            type: detailType ??
                (responses.isEmpty ? 'Description' : responses.first.type));
}

/*
class DetailResponse extends Response {
  final String? description;

  final List<Response> responses;

  final String? detailType;

  final String? linkingId;

  DetailResponse(
      {required this.description,
      required this.responses,
      required int stamp,
      this.linkingId,
      this.detailType,
      super.group,
      super.id})
      : super(
            question: Question.ofType(
                type: detailType ??
                    (responses.isEmpty ? 'Description' : responses.first.type)),
            stamp: stamp);

  DetailResponse.fromJson(Map<String, dynamic> json, QuestionHome home)
      : description = json[DESCRIPTION_FIELD],
        responses = responsesFromJson(json, home),
        detailType = json[TYPE_FIELD],
        linkingId = json["link"],
        super.fromJson(json, home);

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        ...responesToJson(responses),
        TYPE_FIELD: detailType,
        DESCRIPTION_FIELD: description,
      };

  @override
  List<Object?> get props => [...super.props, description, responses];
}
*/

extension ResponseExtensions on Response {
  Response encodeGeneratedQuestion() {
    if (!question.id.contains(generatedIdDelimiter)) return this;

    final String jsonValues = jsonEncode(question.toJson());
    Question newQ;

    switch (question) {
      case FreeResponse q:
        newQ = q.copyWith(id: jsonValues);
      case Numeric q:
        newQ = q.copyWith(id: jsonValues);
      case Check q:
        newQ = q.copyWith(id: jsonValues);
      case MultipleChoice q:
        newQ = q.copyWith(id: jsonValues);
      case AllThatApply q:
        newQ = q.copyWith(id: jsonValues);
    }

    final Response res = this;
    switch (res) {
      case OpenResponse r:
        return OpenResponse(
            question: newQ as FreeResponse,
            response: r.response,
            stamp: r.stamp,
            id: r.id);
      case NumericResponse r:
        return NumericResponse(
            question: newQ as Numeric,
            response: r.response,
            stamp: r.stamp,
            id: r.id);
      case Selected r:
        return Selected(
            question: newQ as Check, stamp: r.stamp, id: r.id, group: r.group);
      case AllResponse r:
        return AllResponse(
            question: newQ as AllThatApply,
            responses: r.responses,
            stamp: r.stamp,
            id: r.id,
            group: r.group);
      case MultiResponse r:
        if (newQ is MultipleChoice) {
          return MultiResponse(
              question: newQ,
              index: r.index,
              stamp: r.stamp,
              id: r.id,
              group: r.group);
        }
        return res;
      default:
        return res;
    }
  }
}
