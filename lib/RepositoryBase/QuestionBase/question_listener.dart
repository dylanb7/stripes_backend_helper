import 'package:flutter/material.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_repo_base.dart';
import 'package:stripes_backend_helper/db_keys.dart';

class QuestionsListener extends ChangeNotifier {
  QuestionsListener({
    List<Response>? responses,
    this.editId,
    DateTime? submitTime,
    String? description,
    bool tried = false,
  }) {
    if (responses != null) {
      for (final res in responses) {
        questions[res.question.id] = res;
      }
    }
    _submitTime = submitTime;
    _description = description;
    _tried = tried;
  }

  factory QuestionsListener.fromJson(
      Map<String, dynamic> json, QuestionHome home) {
    final responses = (json['responses'] as List?)
            ?.map((e) => _responseFromJson(e, home))
            .whereType<Response>()
            .toList() ??
        [];

    return QuestionsListener(
      responses: responses,
      editId: json['editId'],
      submitTime: json['submitTime'] != null
          ? DateTime.tryParse(json['submitTime'])
          : null,
      description: json['description'],
      tried: json['tried'] ?? false,
    );
  }

  static Response? _responseFromJson(
      Map<String, dynamic> json, QuestionHome home) {
    final question = Response.parseQuestion(json[ID_FIELD], home);
    if (question is FreeResponse) return OpenResponse.fromJson(json, home);
    if (question is Numeric) return NumericResponse.fromJson(json, home);
    if (question is Check) return Selected.fromJson(json, home);
    if (question is MultipleChoice) return MultiResponse.fromJson(json, home);
    if (question is AllThatApply) return AllResponse.fromJson(json, home);
    return null;
  }

  Map<String, dynamic> toJson() => {
        'editId': editId,
        'submitTime': submitTime?.toIso8601String(),
        'description': description,
        'tried': tried,
        'responses': questions.values.map((e) => e.toJson()).toList(),
      };

  QuestionsListener copy() => QuestionsListener(
      responses: questions.values.toList(),
      editId: editId,
      submitTime: submitTime,
      description: description,
      tried: tried);

  DateTime? _submitTime;

  DateTime? get submitTime => _submitTime;

  set submitTime(DateTime? dateTime) {
    _submitTime = dateTime;
    notifyListeners();
  }

  final String? editId;

  final Map<String, Response> questions = {};

  final Set<Question> pending = {};

  bool _tried = false;

  bool get tried => _tried;

  set tried(bool val) {
    if (_tried != val) {
      _tried = val;
      notifyListeners();
    }
  }

  String? _description;

  String? get description => _description;

  set description(String? desc) {
    _description = desc;
    notifyListeners();
  }

  void setResponse(Question question, {Response? response}) {
    if (response == null) {
      questions.remove(question.id);
    } else {
      questions[question.id] = response;
    }

    if (isQuestionValid(question)) {
      pending.remove(question);
    } else {
      pending.add(question);
    }

    notifyListeners();
  }

  bool isQuestionValid(Question question) {
    if (question.requirement != null &&
        question.requirement!.groups.isNotEmpty) {
      return question.requirement!.eval(this, contextId: question.id);
    }
    return true;
  }

  void addPendingQuestions(List<Question> questionsToCheck) {
    for (final question in questionsToCheck) {
      if (!isQuestionValid(question)) {
        pending.add(question);
      } else {
        pending.remove(question);
      }
    }
    notifyListeners();
  }

  void addPending(Question question) {
    pending.add(question);
    notifyListeners();
  }

  void removePending(Question question) {
    pending.remove(question);
    notifyListeners();
  }

  void addResponse(Response response) {
    questions[response.question.id] = response;
    notifyListeners();
  }

  Response? fromQuestion(Question question) => questions[question.id];

  void removeResponse(Question question) {
    questions.remove(question.id);
    notifyListeners();
  }

  @override
  String toString() {
    return "$editId | $description | $submitTime\n\n$questions ";
  }
}
