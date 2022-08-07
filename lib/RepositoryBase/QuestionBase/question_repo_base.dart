import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/RepositoryBase/AuthBase/auth_user.dart';

abstract class QuestionRepo<T extends QuestionHome> {
  final AuthUser authUser;

  QuestionRepo({required this.authUser});

  Future<T> get questions;
}

abstract class QuestionHome {
  Map<String, Question> all = {};

  Question fromID(String id) => all[id] ?? Question.empty();
}
