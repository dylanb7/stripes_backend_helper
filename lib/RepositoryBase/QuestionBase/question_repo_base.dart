import 'package:flutter/foundation.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/RepositoryBase/AuthBase/auth_user.dart';

abstract class QuestionRepo<T extends QuestionHome> {
  final AuthUser authUser;

  QuestionRepo({required this.authUser});

  Map<String, List<PageLayout>> getLayouts() => {};

  T get questions;
}

enum RecordType {
  checkIn,
  occurance;
}

@immutable
class RecordPath {
  final List<PageLayout> pages;
  final RecordType type;
  const RecordPath(this.pages, this.type);
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
