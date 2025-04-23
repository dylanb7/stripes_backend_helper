import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_backend_helper/RepositoryBase/AuthBase/auth_user.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_listener.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/record_period.dart';

/*
Default question behavior groups questions by type and adds them to a record path. Displays and entries are preset.


*/

abstract class QuestionRepo<T extends QuestionHome> {
  final AuthUser authUser;

  QuestionRepo({required this.authUser});

  Map<String, DisplayBuilder>? displayOverrides;

  Map<String, QuestionEntry>? entryOverrides;

  Map<String, RecordPath> getLayouts(
          {required BuildContext context,
          QuestionsListener? questionListener}) =>
      {};

  Future<bool> addRecordPath(String category, RecordPath path);

  Future<bool> removeRecordPath(String category);

  Future<bool> addQuestion(Question question);

  Future<bool> removeQuestion(Question question);

  BehaviorSubject<T> get questions;
}

typedef DisplayBuilder<T extends Response<Question>> = Widget Function(
    BuildContext, T);

typedef EntryBuilder<T extends Question> = Widget Function(
    QuestionsListener, BuildContext, T);

class QuestionEntry {
  final bool isSeparateScreen;

  final EntryBuilder entryBuilder;

  const QuestionEntry(
      {required this.isSeparateScreen, required this.entryBuilder});
}

@immutable
class RecordPath {
  final List<PageLayout> pages;
  final Period? period;
  final bool userCreated;
  const RecordPath(
      {required this.pages, this.period, this.userCreated = false});
}

@immutable
class PageLayout {
  final List<String> questionIds;

  final String? header;

  const PageLayout({required this.questionIds, this.header});
}

abstract class QuestionHome {
  Map<String, Question> all = {};

  Map<String, Question> additions = {};

  Map<String, List<Question>> byType();

  Question fromBank(String id) => all[id] ?? additions[id] ?? Question.empty();

  Question fromID(String id) => all[id] ?? Question.empty();
}
