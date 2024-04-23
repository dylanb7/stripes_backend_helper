import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';

class QuestionsListener extends ChangeNotifier with EquatableMixin {
  QuestionsListener(
      {List<Response>? responses,
      this.editId,
      DateTime? submitTime,
      String? desc}) {
    _submitTime = submitTime;
    _description = desc;
    responses?.forEach((res) {
      questions[res.question] = res;
    });
  }

  QuestionsListener.copy(QuestionsListener original)
      : _submitTime = original.submitTime,
        editId = original.editId,
        questions = original.questions,
        pending = original.pending,
        _tried = original._tried,
        _description = original._description;

  DateTime? _submitTime;

  DateTime? get submitTime => _submitTime;

  set submitTime(DateTime? dateTime) {
    _submitTime = dateTime;
    notifyListeners();
  }

  final String? editId;

  Map<Question, Response> questions = {};

  Set<Question> pending = {};

  bool _tried = false;

  bool get tried => _tried;

  set tried(val) {
    if (_tried != val) {
      _tried = val;
      notifyListeners();
    }
  }

  String? _description;

  get description => _description;

  set description(desc) {
    _description = desc;
    notifyListeners();
  }

  setResponse(Question question, {Response? response}) {
    if (response == null) {
      questions.remove(question);
      if (question.isRequired) {
        pending.add(question);
      }
    } else {
      questions[question] = response;
      pending.remove(question);
    }
    notifyListeners();
  }

  addPending(Question question) {
    pending.add(question);
    notifyListeners();
  }

  removePending(Question question) {
    pending.remove(question);
    notifyListeners();
  }

  addResponse(Response response) {
    questions[response.question] = response;
    notifyListeners();
  }

  Response? fromQuestion(Question question) => questions[question];

  removeResponse(Question question) {
    questions.remove(question);
    notifyListeners();
  }

  @override
  String toString() {
    return "$editId | $description | $submitTime\n\n$questions ";
  }

  @override
  List<Object?> get props => [editId, questions, description, submitTime];
}
