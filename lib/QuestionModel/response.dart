import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_repo_base.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_resolver.dart';
import 'package:stripes_backend_helper/db_keys.dart';

import '../RepositoryBase/StampBase/stamp.dart';

@immutable
sealed class Response<E extends Question> extends Stamp with Equatable {
  final E question;

  Response({
    required this.question,
    required super.stamp,
    super.id,
    super.group,
  }) : super(type: question.type);

  Response.fromJson(Map<String, dynamic> json, QuestionHome home)
    : question = parseQuestion(json[ID_FIELD], home) as E,
      super.fromJson(json);

  static Question parseQuestion(dynamic idField, QuestionHome home) {
    if (idField is String && idField.startsWith('{')) {
      try {
        final questionJson = jsonDecode(idField) as Map<String, dynamic>;
        if (!QuestionType.values.any(
          (type) => type.id == questionJson['questionType'],
        )) {
          throw const FormatException('Unsupported embedded question type');
        }
        return Question.fromJson(questionJson);
      } catch (error) {
        throw FormatException('Invalid embedded question definition: $error');
      }
    }

    if (idField is! String || idField.isEmpty) {
      throw const FormatException('Question ID is missing or invalid');
    }
    return home.forDisplay(idField) ??
        (throw FormatException('Question definition is not loaded: $idField'));
  }

  Response encodeGeneratedQuestion() {
    if (!isGeneratedQuestion) return this;

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
          id: r.id,
        );
      case NumericResponse r:
        return NumericResponse(
          question: newQ as Numeric,
          response: r.response,
          stamp: r.stamp,
          id: r.id,
        );
      case Selected r:
        return Selected(
          question: newQ as Check,
          stamp: r.stamp,
          id: r.id,
          group: r.group,
        );
      case AllResponse r:
        return AllResponse(
          question: newQ as AllThatApply,
          responses: r.responses,
          stamp: r.stamp,
          id: r.id,
          group: r.group,
        );
      case MultiResponse r:
        if (newQ is MultipleChoice) {
          return MultiResponse(
            question: newQ,
            index: r.index,
            stamp: r.stamp,
            id: r.id,
            group: r.group,
          );
        }
        return res;
      default:
        return res;
    }
  }

  bool get isGeneratedQuestion => question.id.contains(generatedIdDelimiter);

  @override
  Map<String, dynamic> toJson() {
    if (isGeneratedQuestion) {
      return {...super.toJson(), ID_FIELD: jsonEncode(question.toJson())};
    }
    return {...super.toJson(), ID_FIELD: question.id};
  }
}

/// An answer whose definition is unavailable or incompatible. It is not a
/// selected/answered Check. Keep the original item intact until it can resolve.
class UnresolvedResponse extends Response<Question> {
  final String reason;
  final String _rawJson;

  UnresolvedResponse({
    required Map<String, dynamic> raw,
    required this.reason,
    required super.stamp,
    super.group,
  }) : _rawJson = jsonEncode(raw),
       super(
         id: raw[STAMP_ID] is String ? raw[STAMP_ID] as String : null,
         question: Check(
           id: raw[ID_FIELD] is String
               ? raw[ID_FIELD] as String
               : 'unresolved:${jsonEncode(raw)}',
           prompt: 'Answer unavailable',
           type: '',
           enabled: false,
           locked: true,
         ),
       );

  Map<String, dynamic> get raw =>
      Map<String, dynamic>.from(jsonDecode(_rawJson) as Map);

  Response resolve(QuestionHome home) =>
      decodeResponseItem(raw, home, stamp, group);

  @override
  bool get isGeneratedQuestion => false;
  @override
  Response encodeGeneratedQuestion() => this;
  @override
  Map<String, dynamic> toJson() => {...super.toJson(), ...raw};
  @override
  List<Object?> get props => [...super.props, _rawJson, reason];
}

/// Parse one answer without making a missing study definition a record-level
/// failure. Re-running this against an updated QuestionHome retries resolution.
Response decodeResponseItem(
  Map<String, dynamic> raw,
  QuestionHome home,
  int stamp,
  String? group,
) {
  try {
    final question = Response.parseQuestion(raw[ID_FIELD], home);
    final id = raw[STAMP_ID] as String?;
    const answerKeys = {
      RESPONSE_FIELD,
      NUMERIC_RESPONSE_FIELD,
      SELECTED_FIELD,
      SELECTED_FIELDS,
    };
    const supportedKeys = {
      ID_FIELD,
      STAMP_ID,
      STAMP_FIELD,
      TYPE_FIELD,
      'group_value',
      ...answerKeys,
    };
    if (raw.keys.any((key) => !supportedKeys.contains(key))) {
      throw const FormatException('Unsupported answer fields');
    }
    final populated = answerKeys.where((key) => raw[key] != null).toList();
    final expectedKey = switch (question) {
      FreeResponse() => RESPONSE_FIELD,
      Numeric() => NUMERIC_RESPONSE_FIELD,
      MultipleChoice() => SELECTED_FIELD,
      AllThatApply() => SELECTED_FIELDS,
      Check() => null,
    };
    if (expectedKey == null
        ? populated.isNotEmpty
        : populated.length != 1 || populated.single != expectedKey) {
      throw const FormatException('Answer does not match the question type');
    }
    switch (question) {
      case FreeResponse():
        return OpenResponse(
          question: question,
          stamp: stamp,
          id: id,
          group: group,
          response: raw[RESPONSE_FIELD] as String,
        );
      case Numeric():
        return NumericResponse(
          question: question,
          stamp: stamp,
          id: id,
          group: group,
          response: raw[NUMERIC_RESPONSE_FIELD] as num,
        );
      case MultipleChoice():
        final index = raw[SELECTED_FIELD] as int;
        if (index < 0 || index >= question.choices.length) {
          throw const FormatException('Selected option is not in the question');
        }
        return MultiResponse(
          question: question,
          stamp: stamp,
          id: id,
          group: group,
          index: index,
        );
      case AllThatApply():
        final indexes = List<int>.from(raw[SELECTED_FIELDS] as List);
        if (indexes.any(
          (index) => index < 0 || index >= question.choices.length,
        )) {
          throw const FormatException('Selected option is not in the question');
        }
        return AllResponse(
          question: question,
          stamp: stamp,
          id: id,
          group: group,
          responses: indexes,
        );
      case Check():
        return Selected(question: question, stamp: stamp, id: id, group: group);
    }
  } on FormatException catch (error) {
    return UnresolvedResponse(
      raw: raw,
      reason: error.message,
      stamp: stamp,
      group: group,
    );
  } on TypeError {
    return UnresolvedResponse(
      raw: raw,
      reason: 'Invalid answer value or question definition',
      stamp: stamp,
      group: group,
    );
  }
}

class OpenResponse extends Response<FreeResponse> {
  final String response;

  OpenResponse({
    required FreeResponse question,
    required super.stamp,
    required this.response,
    super.group,
    super.id,
  }) : super(question: question);

  OpenResponse.fromJson(Map<String, dynamic> json, QuestionHome home)
    : response = json[RESPONSE_FIELD],
      super.fromJson(json, home);

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    RESPONSE_FIELD: response,
  };

  @override
  List<Object?> get props => [...super.props, response, question];
}

class NumericResponse extends Response<Numeric> {
  final num response;
  NumericResponse({
    required Numeric question,
    required int stamp,
    required this.response,
    super.group,
    super.id,
  }) : super(question: question, stamp: stamp);

  NumericResponse.fromJson(Map<String, dynamic> json, QuestionHome home)
    : response = json[NUMERIC_RESPONSE_FIELD],
      super.fromJson(json, home);

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    NUMERIC_RESPONSE_FIELD: response,
  };

  @override
  List<Object?> get props => [...super.props, response, question];
}

class Selected extends Response<Check> {
  Selected({required Check question, required int stamp, super.id, super.group})
    : super(question: question, stamp: stamp);

  Selected.fromJson(Map<String, dynamic> json, QuestionHome home)
    : super.fromJson(json, home);

  @override
  Map<String, dynamic> toJson() => super.toJson();

  @override
  List<Object?> get props => [...super.props, question];
}

class MultiResponse extends Response<MultipleChoice> {
  final int index;

  MultiResponse({
    required MultipleChoice question,
    required int stamp,
    required this.index,
    super.group,
    super.id,
  }) : super(question: question, stamp: stamp);

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

  AllResponse({
    required AllThatApply question,
    required int stamp,
    required this.responses,
    super.group,
    super.id,
  }) : super(question: question, stamp: stamp);

  AllResponse.fromJson(Map<String, dynamic> json, QuestionHome home)
    : responses = json[SELECTED_FIELDS],
      super.fromJson(json, home);

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    SELECTED_FIELDS: responses,
  };

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
  DetailResponse({
    this.description,
    this.linkingId,
    required super.responses,
    super.group,
    super.id,
    required super.stamp,
    String? detailType,
  }) : super(
         type:
             detailType ??
             (responses.isEmpty ? 'Description' : responses.first.type),
       );
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
          id: r.id,
        );
      case NumericResponse r:
        return NumericResponse(
          question: newQ as Numeric,
          response: r.response,
          stamp: r.stamp,
          id: r.id,
        );
      case Selected r:
        return Selected(
          question: newQ as Check,
          stamp: r.stamp,
          id: r.id,
          group: r.group,
        );
      case AllResponse r:
        return AllResponse(
          question: newQ as AllThatApply,
          responses: r.responses,
          stamp: r.stamp,
          id: r.id,
          group: r.group,
        );
      case MultiResponse r:
        if (newQ is MultipleChoice) {
          return MultiResponse(
            question: newQ,
            index: r.index,
            stamp: r.stamp,
            id: r.id,
            group: r.group,
          );
        }
        return res;
      default:
        return res;
    }
  }
}
