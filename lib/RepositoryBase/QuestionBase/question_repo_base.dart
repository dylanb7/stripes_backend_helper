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

  Future<bool> addRecordPath(RecordPath path);

  Future<bool> setEnabled(RecordPath recordPath, bool enabled);

  Future<bool> removeRecordPath(RecordPath category);

  Future<bool> addQuestion(Question question);

  Future<bool> setQuestionEnabled(Question recordPath, bool enabled);

  Future<bool> removeQuestion(Question question);

  BehaviorSubject<List<RecordPath>> get layouts;

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

  final DependsOn dependsOn;

  final String? header;

  const PageLayout(
      {required this.questionIds,
      this.dependsOn = const DependsOn.nothing(),
      this.header});

  Map<String, dynamic> toJson() {
    return {
      'header': header,
      'ids': questionIds.join("|"),
      'dependsOn': dependsOn.toString()
    };
  }

  static PageLayout fromJson(Map<String, dynamic> json) => PageLayout(
      questionIds:
          json['ids'] is String ? (json['ids'] as String).split("|") : [],
      header: json['header'],
      dependsOn: DependsOn.fromString(json['dependsOn']));
}

enum CheckType {
  exists("exists"),
  equals("equals");

  final String value;
  const CheckType(this.value);

  static CheckType? fromValue(String value) {
    if (value == "exists") return CheckType.exists;
    if (value == "equals") return CheckType.equals;
    return null;
  }
}

@immutable
class Relation {
  final String qid;
  final dynamic response;
  final QuestionType questionType;
  final CheckType type;
  const Relation(
      {required this.qid,
      required this.questionType,
      this.response,
      this.type = CheckType.exists});

  const Relation.exists({required this.qid})
      : questionType = QuestionType.check,
        type = CheckType.exists,
        response = null;

  static Relation from<E extends Response>(
      {required String qid,
      required dynamic response,
      CheckType type = CheckType.exists}) {
    if (E is OpenResponse) {
      return Relation(
          qid: qid,
          response: response,
          questionType: QuestionType.freeResponse,
          type: type);
    }
    if (E is NumericResponse) {
      return Relation(
          qid: qid,
          response: response,
          questionType: QuestionType.slider,
          type: type);
    }
    if (E is MultiResponse) {
      return Relation(
          qid: qid,
          response: response,
          questionType: QuestionType.multipleChoice,
          type: type);
    }
    if (E is AllResponse) {
      return Relation(
          qid: qid,
          response: response,
          questionType: QuestionType.allThatApply,
          type: type);
    }
    return Relation(
        qid: qid,
        response: response,
        questionType: QuestionType.check,
        type: type);
  }

  @override
  String toString() {
    if (questionType == QuestionType.allThatApply) {
      return [
        questionType.id,
        qid,
        response is List<int> ? (response as List<int>).join("|") : null,
        type.value
      ].join("^");
    }
    return [questionType.id, qid, "$response", type.value].join("^");
  }

  static Relation? fromString(String value) {
    final List<String> values = value.split("^");
    if (values.length != 4) return null;
    final CheckType? checkType = CheckType.fromValue(values[3]);
    final QuestionType questionType = QuestionType.fromId(values[0]);
    if (checkType == null) return null;
    if (questionType == QuestionType.check || checkType == CheckType.exists) {
      return Relation.exists(qid: values[1]);
    }
    final String response = values[2];
    if (questionType == QuestionType.multipleChoice ||
        questionType == QuestionType.slider) {
      return Relation(
          qid: values[1],
          questionType: questionType,
          response: int.tryParse(response),
          type: checkType);
    }
    if (questionType == QuestionType.allThatApply) {
      return Relation(
          qid: values[1],
          questionType: questionType,
          response: response
              .split("|")
              .map((val) => int.tryParse(val))
              .whereType<int>()
              .toList(),
          type: checkType);
    }
    return Relation(
        qid: values[1],
        response: response,
        questionType: questionType,
        type: checkType);
  }
}

enum Op {
  all("all"),
  one("one");

  final String value;

  const Op(this.value);

  static Op? fromValue(String value) {
    if (value == "all") return Op.all;
    if (value == "one") return Op.one;
    return null;
  }
}

@immutable
class RelationOp {
  final List<Relation> relations;
  final Op op;

  const RelationOp({required this.relations, required this.op});

  @override
  String toString() {
    return [relations.join("&"), op.value].join("}");
  }

  static RelationOp? fromString(String val) {
    final List<String> values = val.split("}");
    if (values.length != 2) return null;
    final Op? op = Op.fromValue(values[1]);
    final List<Relation> relations = values[0]
        .split("&")
        .map((value) => Relation.fromString(value))
        .whereType<Relation>()
        .toList();
    if (op == null) return null;
    return RelationOp(relations: relations, op: op);
  }
}

@immutable
class DependsOn {
  final List<RelationOp> relations;
  const DependsOn(this.relations);

  factory DependsOn.init() => const DependsOn([]);

  const DependsOn.nothing() : relations = const [];

  DependsOn allOf(List<Relation> rels) =>
      DependsOn([...relations, RelationOp(relations: rels, op: Op.all)]);

  DependsOn oneOf(List<Relation> rels) =>
      DependsOn([...relations, RelationOp(relations: rels, op: Op.one)]);

  bool eval(QuestionsListener questionListener) {
    if (relations.isEmpty) return true;

    Question? from(String id) {
      final List<Question> withId = questionListener.questions.keys
          .where(((key) => key.id == id))
          .toList();
      return withId.isEmpty ? null : withId[0];
    }

    bool getEquals(Relation rel, Response? res) {
      if (res == null) return false;
      switch (rel.questionType) {
        case QuestionType.check:
          return true;
        case QuestionType.freeResponse:
          return (res as OpenResponse).response == rel.response;
        case QuestionType.slider:
          return (res as NumericResponse).response == rel.response;
        case QuestionType.multipleChoice:
          return (res as MultiResponse).index == rel.response;
        case QuestionType.allThatApply:
          return (res as AllResponse).responses == rel.response;
      }
    }

    for (final RelationOp relationOp in relations) {
      bool passed = false;
      for (final Relation rel in relationOp.relations) {
        final Question? withId = from(rel.qid);
        final bool relationEval = withId == null
            ? false
            : rel.type == CheckType.exists
                ? true
                : getEquals(rel, questionListener.fromQuestion(withId));
        if (relationOp.op == Op.all && !relationEval) return false;
        if (relationOp.op == Op.one && relationEval) {
          passed = true;
          break;
        }
      }
      if (!passed) return false;
    }
    return true;
  }

  @override
  String toString() {
    return relations.join("~");
  }

  static DependsOn fromString(String val) {
    print(val);
    List<RelationOp> ops = val
        .split("~")
        .map((rel) => RelationOp.fromString(rel))
        .whereType<RelationOp>()
        .toList();
    return DependsOn(ops);
  }
}

abstract class QuestionHome {
  Map<String, Question> all = {};

  Map<String, Question> additions = {};

  Map<String, List<Question>> byType();

  Question fromBank(String id) => all[id] ?? additions[id] ?? Question.empty();

  Question fromID(String id) => all[id] ?? Question.empty();
}
