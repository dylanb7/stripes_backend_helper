import 'package:flutter/foundation.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/RepositoryBase/AuthBase/auth_user.dart';

abstract class QuestionRepo<T extends QuestionHome> {
  final AuthUser authUser;

  QuestionRepo({required this.authUser});

  Map<String, List<PageLayout>> getLayouts() => {};

  T get questions;
}

@immutable
class RecordPath {
  final List<PageLayout> pages;
  final Duration? period;
  const RecordPath(this.pages, this.period);
}

@immutable
class PageLayout {
  final List<Question> questions;

  final String? header;

  const PageLayout({required this.questions, this.header});
}

abstract class QuestionHome {
  Map<String, Question> all = {};

  Question fromID(String id) => all[id] ?? Question.empty();
}
