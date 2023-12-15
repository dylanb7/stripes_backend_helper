import 'package:flutter/material.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';

class QuestionsListener extends ChangeNotifier {
  final Map<Question, Response> questions = {};

  final Set<Question> pending = {};

  bool _tried = false;

  get tried => _tried;

  set tried(val) {
    _tried = val;
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
}
