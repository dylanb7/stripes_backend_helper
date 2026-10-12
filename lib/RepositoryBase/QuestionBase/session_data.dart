import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_repo_base.dart';
import 'package:stripes_backend_helper/db_keys.dart';

/// Immutable snapshot of a recording session's user responses and metadata.
///
/// Contains no reactive logic or manual validation sets.
/// Used for serialization, draft saving, route passing, and as the underlying
/// data model for [SessionGraph].
@immutable
class SessionData with EquatableMixin {
  final String? editId;
  final DateTime? submitTime;
  final String? description;
  final bool tried;
  final Map<String, Response> responses;

  const SessionData({
    this.editId,
    this.submitTime,
    this.description,
    this.tried = false,
    this.responses = const {},
  });

  factory SessionData.fromJson(Map<String, dynamic> json, QuestionHome home) {
    final responseList =
        (json['responses'] as List?)
            ?.map((e) => _responseFromJson(e, home))
            .whereType<Response>()
            .toList() ??
        [];

    final responseMap = <String, Response>{};
    for (final res in responseList) {
      responseMap[res.question.id] = res;
    }

    return SessionData(
      editId: json['editId'],
      submitTime: json['submitTime'] != null
          ? DateTime.tryParse(json['submitTime'])?.toUtc()
          : null,
      description: json['description'],
      tried: json['tried'] ?? false,
      responses: Map.unmodifiable(responseMap),
    );
  }

  static Response? _responseFromJson(
    Map<String, dynamic> json,
    QuestionHome home,
  ) {
    return decodeResponseItem(
      json,
      home,
      json[STAMP_FIELD] as int? ?? 0,
      json['group_value'] as String?,
    );
  }

  bool get hasUnresolvedResponses =>
      responses.values.any((r) => r is UnresolvedResponse);

  SessionData resolveQuestions(QuestionHome home) => copyWith(
    responses: {
      for (final item in responses.entries)
        item.key: item.value is UnresolvedResponse
            ? (item.value as UnresolvedResponse).resolve(home)
            : decodeResponseItem(
                item.value.toJson(),
                home,
                item.value.stamp,
                item.value.group,
              ),
    },
  );

  Map<String, dynamic> toJson() => {
    'editId': editId,
    'submitTime': submitTime?.toUtc().toIso8601String(),
    'description': description,
    'tried': tried,
    'responses': responses.values.map((e) => e.toJson()).toList(),
  };

  SessionData copyWith({
    String? editId,
    DateTime? submitTime,
    String? description,
    bool? tried,
    Map<String, Response>? responses,
  }) {
    return SessionData(
      editId: editId ?? this.editId,
      submitTime: submitTime ?? this.submitTime,
      description: description ?? this.description,
      tried: tried ?? this.tried,
      responses: responses != null
          ? Map.unmodifiable(responses)
          : this.responses,
    );
  }

  Response? fromQuestion(Question question) => responses[question.id];

  Response? responseFor(String questionId) => responses[questionId];

  @override
  List<Object?> get props => [
    editId,
    submitTime,
    description,
    tried,
    responses,
  ];

  @override
  String toString() {
    return 'SessionData(editId: $editId, description: $description, submitTime: $submitTime, responsesCount: ${responses.length})';
  }
}
