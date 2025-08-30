import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_repo_base.dart';
import 'package:stripes_backend_helper/db_keys.dart';

import '../RepositoryBase/StampBase/stamp.dart';

@immutable
sealed class Response<E extends Question> extends Stamp with EquatableMixin {
  final E question;

  Response(
      {required this.question, required super.stamp, super.id, super.group})
      : super(type: question.type);

  Response.fromJson(Map<String, dynamic> json, QuestionHome home)
      : question = home.fromBank(json[ID_FIELD]) as E,
        super.fromJson(json);

  @override
  Map<String, dynamic> toJson() {
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
      {...super.toJson(), ID_FIELD: question.id, RESPONSE_FIELD: response};

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
        ID_FIELD: question.id,
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
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        ID_FIELD: question.id,
      };

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
  Map<String, dynamic> toJson() =>
      {...super.toJson(), ID_FIELD: question.id, SELECTED_FIELD: index};

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
      {...super.toJson(), ID_FIELD: question.id, SELECTED_FIELDS: responses};

  List<String> get choices =>
      responses.map((res) => question.choices[res]).toList();

  @override
  List<Object?> get props => [...super.props, responses, question];
}

abstract class ResponseWrap extends Response {
  final List<Response> responses;

  ResponseWrap({
    required this.responses,
    required super.group,
    required super.stamp,
    required String type,
    super.id,
  }) : super(question: Question.ofType(type: type));
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
Map<String, dynamic> responesToJson(List<Response> responses) {
  Map<String, dynamic> res = {};
  for (int i = 0; i < responses.length; i++) {
    res['$i'] = responses[i].toJson();
  }
  return res;
}

Response responseFromJson(Map<String, dynamic> json, QuestionHome home) {
  if (json.containsKey(SELECTED_FIELDS)) {
    return AllResponse.fromJson(json, home);
  }
  if (json.containsKey(SELECTED_FIELD)) {
    return MultiResponse.fromJson(json, home);
  }
  if (json.containsKey(NUMERIC_RESPONSE_FIELD)) {
    return NumericResponse.fromJson(json, home);
  }
  if (json.containsKey(RESPONSE_FIELD)) {
    return OpenResponse.fromJson(json, home);
  }

  return Selected.fromJson(json, home);
}

List<Response> responsesFromJson(Map<String, dynamic> json, QuestionHome home) {
  List<Response> res = [];
  for (int i = 0; true; i++) {
    final String key = '$i';
    if (!json.containsKey(key)) return res;
    res.add(responseFromJson(json[key], home));
  }
}
