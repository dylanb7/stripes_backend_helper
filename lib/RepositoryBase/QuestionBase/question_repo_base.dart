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

  List<RecordPath> getLayouts(
          {required BuildContext context,
          QuestionsListener? questionListener}) =>
      [];

  Future<bool> addRecordPath(RecordPath path);

  Future<bool> setEnabled(RecordPath recordPath, bool enabled);

  Future<bool> removeRecordPath(RecordPath category);

  Future<bool> addQuestion(Question question);

  Future<bool> setQuestionEnabled(Question recordPath, bool enabled);

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
  final String name;
  final List<PageLayout> pages;
  final Period? period;
  final bool userCreated, enabled;
  const RecordPath(
      {required this.name,
      required this.pages,
      this.period,
      this.userCreated = false,
      this.enabled = true});

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'period': period?.toId(),
      'pages': pages.map((page) => page.toJson()).toList(),
      'userCreated': userCreated ? 1 : 0,
      'enabled': enabled ? 1 : 0
    };
  }

  static RecordPath fromJson(Map<String, dynamic> json) {
    return RecordPath(
        name: json['name'],
        pages: json['pages'] is List
            ? (json['pages'] as List)
                .map((pageJson) => PageLayout.fromJson(pageJson))
                .toList()
            : [],
        period: json['period'] is String ? Period.fromId(json['period']) : null,
        userCreated: json['userCreated'] == 1,
        enabled: json['enabled'] == 1);
  }
}

@immutable
class PageLayout {
  final List<String> questionIds;

  final String? header;

  const PageLayout({required this.questionIds, this.header});

  Map<String, dynamic> toJson() {
    return {'header': header, 'ids': questionIds.join("|")};
  }

  static PageLayout fromJson(Map<String, dynamic> json) => PageLayout(
      questionIds:
          json['ids'] is String ? (json['ids'] as String).split("|") : [],
      header: json['header']);
}

abstract class QuestionHome {
  Map<String, Question> all = {};

  Map<String, Question> additions = {};

  Map<String, List<Question>> byType();

  Question fromBank(String id) => all[id] ?? additions[id] ?? Question.empty();

  Question fromID(String id) => all[id] ?? Question.empty();
}
