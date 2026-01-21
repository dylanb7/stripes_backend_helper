import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_backend_helper/RepositoryBase/AuthBase/auth_user.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/depends_on.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/requirement.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_listener.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/record_period.dart';
import 'package:stripes_backend_helper/RepositoryBase/SubBase/sub_user.dart';
import 'package:uuid/uuid.dart';

export 'depends_on.dart';

/*
Default question behavior groups questions by type and adds them to a record path. Displays and entries are preset.


*/

abstract class QuestionRepo<T extends QuestionHome> {
  final AuthUser authUser;

  final SubUser subUser;

  QuestionRepo({required this.authUser, required this.subUser});

  Map<String, DisplayBuilder>? displayOverrides;

  Map<String, QuestionEntry>? entryOverrides;

  Future<bool> addRecordPath(RecordPath path);

  Future<bool> setPathEnabled(RecordPath recordPath, bool enabled);

  Future<bool> removeRecordPath(RecordPath category);

  Future<bool> updateRecordPath(RecordPath path);

  Future<bool> addQuestion(Question question);

  Future<bool> setQuestionEnabled(Question recordPath, bool enabled);

  Future<bool> removeQuestion(Question question);

  BehaviorSubject<List<RecordPath>> get layouts;

  BehaviorSubject<T> get questions;
}

mixin BaselineRecordPathMixin<T extends QuestionHome> on QuestionRepo<T> {
  BehaviorSubject<List<RecordPath>> get baselineRecordPaths;
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
class RecordPath extends Equatable {
  final String? id;
  final String name;
  final List<PageLayout> pages;
  final Period? period;
  final bool userCreated, enabled, locked, isBaseline;
  final String? fromBaseline;
  RecordPath(
      {required this.name,
      required this.pages,
      String? uid,
      this.period,
      this.userCreated = false,
      this.enabled = true,
      this.locked = false,
      this.isBaseline = false,
      this.fromBaseline})
      : id = uid ?? const Uuid().v4();

  RecordPath copyWith(
          {String? name,
          List<PageLayout>? pages,
          Period? period,
          bool? userCreated,
          bool? enabled,
          bool? locked,
          bool? isBaseline,
          String? fromBaseline}) =>
      RecordPath(
          uid: id,
          name: name ?? this.name,
          pages: pages ?? this.pages,
          period: period ?? this.period,
          userCreated: userCreated ?? this.userCreated,
          enabled: enabled ?? this.enabled,
          locked: locked ?? this.locked,
          isBaseline: isBaseline ?? this.isBaseline,
          fromBaseline: fromBaseline ?? this.fromBaseline);

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'period': period?.toId(),
      'pages': pages.map((page) => page.toJson()).toList(),
      'userCreated': userCreated ? 1 : 0,
      'enabled': enabled ? 1 : 0,
      'isBaseline': isBaseline ? 1 : 0,
      'fromBaseline': fromBaseline,
      if (id != null) 'id': id
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
        enabled: json['enabled'] == 1,
        locked: json['locked'] == 1,
        isBaseline: json['isBaseline'] == 1,
        fromBaseline: json['fromBaseline'],
        uid: json['id']);
  }

  @override
  List<Object?> get props => [
        name,
        period?.toId(),
        ...pages,
        id,
        userCreated,
        enabled,
        locked,
        isBaseline,
        fromBaseline
      ];
}

@immutable
class PageLayout extends Equatable {
  final String? id;

  final List<String> questionIds;

  final DependsOn dependsOn;

  final Requirement requirement;

  final String? header;

  PageLayout(
      {required this.questionIds,
      this.dependsOn = const DependsOn.nothing(),
      this.requirement = const Requirement.nothing(),
      this.header,
      String? uid})
      : id = uid ?? const Uuid().v4();

  PageLayout copyWith(
          {List<String>? questionIds,
          DependsOn? dependsOn,
          Requirement? requirement,
          String? header}) =>
      PageLayout(
          uid: id,
          questionIds: questionIds ?? this.questionIds,
          dependsOn: dependsOn ?? this.dependsOn,
          requirement: requirement ?? this.requirement,
          header: header ?? this.header);

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'header': header,
      'ids': questionIds.join("|"),
      'dependsOn': dependsOn.toString(),
      'requirement': requirement.toString()
    };
  }

  static PageLayout fromJson(Map<String, dynamic> json) => PageLayout(
      uid: json['id'],
      questionIds:
          json['ids'] is String ? (json['ids'] as String).split("|") : [],
      header: json['header'],
      dependsOn: DependsOn.fromString(json['dependsOn']),
      requirement: Requirement.fromString(json['requirement'] ?? ''));

  @override
  List<Object?> get props =>
      [id, ...questionIds, dependsOn, requirement, header];
}

@immutable
class LoadedPageLayout extends Equatable {
  final String? id;

  final List<Question> questions;

  final DependsOn dependsOn;

  final Requirement requirement;

  final String? header;

  const LoadedPageLayout(
      {required this.questions,
      this.header,
      required this.dependsOn,
      required this.requirement,
      this.id});

  LoadedPageLayout copyWith(
          {List<Question>? questions,
          DependsOn? dependsOn,
          Requirement? requirement,
          String? header}) =>
      LoadedPageLayout(
          questions: questions ?? this.questions,
          dependsOn: dependsOn ?? this.dependsOn,
          requirement: requirement ?? this.requirement,
          header: header ?? this.header);

  PageLayout toPageLayout() => PageLayout(
      uid: id,
      questionIds: questions.map((question) => question.id).toList(),
      dependsOn: dependsOn,
      requirement: requirement,
      header: header);

  LoadedPageLayout.from(
      {required PageLayout layout,
      required QuestionHome home,
      bool forDisplay = true})
      : dependsOn = layout.dependsOn,
        requirement = layout.requirement,
        header = layout.header,
        questions = layout.questionIds
            .map(
                (qid) => forDisplay ? home.forDisplay(qid) : home.fromBank(qid))
            .whereType<Question>()
            .toList(),
        id = layout.id;

  @override
  List<Object?> get props => [questions, dependsOn, requirement, header];
}

abstract class QuestionHome {
  Map<String, Question> all = {};

  Map<String, Question> additions = {};

  Map<String, Question> deleted = {};

  Map<String, List<Question>> byType();

  Question? fromBank(String id) => all[id] ?? additions[id];

  Question? fromID(String id) => all[id];

  Question? forDisplay(String id) => fromBank(id) ?? deleted[id];
}
