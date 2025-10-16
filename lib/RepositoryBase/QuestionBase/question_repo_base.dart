import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_backend_helper/RepositoryBase/AuthBase/auth_user.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_listener.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/record_period.dart';
import 'package:stripes_backend_helper/RepositoryBase/SubBase/sub_user.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:yaml/yaml.dart';
import 'package:flutter/widgets.dart';

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
  final bool userCreated, enabled, locked;
  RecordPath(
      {required this.name,
      required this.pages,
      String? uid,
      this.period,
      this.userCreated = false,
      this.enabled = true,
      this.locked = false})
      : id = uid ?? const Uuid().v4();

  RecordPath copyWith(
          {String? name,
          List<PageLayout>? pages,
          Period? period,
          bool? userCreated,
          bool? enabled,
          bool? locked}) =>
      RecordPath(
          uid: id,
          name: name ?? this.name,
          pages: pages ?? this.pages,
          period: period ?? this.period,
          userCreated: userCreated ?? this.userCreated,
          enabled: enabled ?? this.enabled,
          locked: locked ?? this.locked);

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'period': period?.toId(),
      'pages': pages.map((page) => page.toJson()).toList(),
      'userCreated': userCreated ? 1 : 0,
      'enabled': enabled ? 1 : 0,
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
        uid: json['id']);
  }

  @override
  List<Object?> get props =>
      [name, period?.toId(), ...pages, id, userCreated, enabled, locked];
}

@immutable
class PageLayout extends Equatable {
  final String? id;

  final List<String> questionIds;

  final DependsOn dependsOn;

  final String? header;

  PageLayout(
      {required this.questionIds,
      this.dependsOn = const DependsOn.nothing(),
      this.header,
      String? uid})
      : id = uid ?? const Uuid().v4();

  PageLayout copyWith(
          {List<String>? questionIds, DependsOn? dependsOn, String? header}) =>
      PageLayout(
          uid: id,
          questionIds: questionIds ?? this.questionIds,
          dependsOn: dependsOn ?? this.dependsOn,
          header: header ?? this.header);

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'header': header,
      'ids': questionIds.join("|"),
      'dependsOn': dependsOn.toString()
    };
  }

  static PageLayout fromJson(Map<String, dynamic> json) => PageLayout(
      uid: json['id'],
      questionIds:
          json['ids'] is String ? (json['ids'] as String).split("|") : [],
      header: json['header'],
      dependsOn: DependsOn.fromString(json['dependsOn']));

  @override
  List<Object?> get props => [id, ...questionIds, dependsOn, header];
}

@immutable
class LoadedPageLayout extends Equatable {
  final String? id;

  final List<Question> questions;

  final DependsOn dependsOn;

  final String? header;

  const LoadedPageLayout(
      {required this.questions, this.header, required this.dependsOn, this.id});

  LoadedPageLayout copyWith(
          {List<Question>? questions, DependsOn? dependsOn, String? header}) =>
      LoadedPageLayout(
          questions: questions ?? this.questions,
          dependsOn: dependsOn ?? this.dependsOn,
          header: header ?? this.header);

  PageLayout toPageLayout() => PageLayout(
      uid: id,
      questionIds: questions.map((question) => question.id).toList(),
      dependsOn: dependsOn,
      header: header);

  LoadedPageLayout.from(
      {required PageLayout layout,
      required QuestionHome home,
      bool forDisplay = true})
      : dependsOn = layout.dependsOn,
        header = layout.header,
        questions = layout.questionIds
            .map(
                (qid) => forDisplay ? home.forDisplay(qid) : home.fromBank(qid))
            .whereType<Question>()
            .toList(),
        id = layout.id;

  @override
  List<Object?> get props => [questions, dependsOn, header];
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
class Relation extends Equatable {
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

  static Relation equals<E extends Response>(
      {required String qid,
      required dynamic response,
      CheckType type = CheckType.equals}) {
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
    return Relation.exists(qid: qid);
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

  @override
  List<Object?> get props => [qid, response, questionType.id, type.value];
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
class RelationOp extends Equatable {
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

  @override
  List<Object?> get props => [...relations, op.value];
}

@immutable
class DependsOn extends Equatable {
  final List<RelationOp> operations;
  const DependsOn(this.operations);

  factory DependsOn.init() => const DependsOn([]);

  const DependsOn.nothing() : operations = const [];

  factory DependsOn.fromYaml(Map<String, dynamic> yamlData) {
    DependsOn dependsOn = const DependsOn.nothing();

    Relation? parseRelation(Map<String, dynamic> item) {
      const existsKey = 'exists';

      if (item.containsKey(existsKey)) {
        return Relation.exists(qid: item[existsKey]);
      }
      const questionIdKey = 'questionId';
      const equalsKey = 'equals';
      if (!item.containsKey(questionIdKey)) {
        return null;
      }
      final String questionIdSlug = item[questionIdKey];

      if (item.containsKey(equalsKey)) {
        final dynamic equalsSlug = item[equalsKey];

        int? equalsValue = int.tryParse(equalsSlug);
        if (equalsValue != null) {
          return Relation.equals(qid: questionIdSlug, response: equalsValue);
        }
      }

      const textKey = "text";

      if (item.containsKey(textKey)) {
        final dynamic textSlug = item[textKey];

        if (textSlug is! String) return null;
        return Relation.equals(qid: questionIdSlug, response: textSlug);
      }

      const responsesKey = "responses";

      if (item.containsKey(responsesKey)) {
        final dynamic responsesSlug = item[responsesKey];
        if (responsesSlug is! String) return null;
        final List<int> parsedResponse = responsesSlug
            .split(',')
            .map(int.tryParse)
            .whereType<int>()
            .toList();
        return Relation.equals(qid: questionIdSlug, response: parsedResponse);
      }
      return null;
    }

    if (yamlData.containsKey('oneOf')) {
      final List<dynamic> conditions = yamlData['oneOf'] as List<dynamic>;
      final relations = conditions
          .map((cond) {
            final Map<String, dynamic> item = cond as Map<String, dynamic>;
            return parseRelation(item);
          })
          .whereType<Relation>()
          .toList();
      dependsOn = dependsOn.oneOf(relations);
    }

    if (yamlData.containsKey('allOf')) {
      final List<dynamic> conditions = yamlData['allOf'] as List<dynamic>;
      final relations = conditions
          .map((cond) {
            final Map<String, dynamic> item = cond as Map<String, dynamic>;
            return parseRelation(item);
          })
          .whereType<Relation>()
          .toList();
      dependsOn = dependsOn.allOf(relations);
    }

    return dependsOn;
  }

  DependsOn allOf(List<Relation> rels) =>
      DependsOn([...operations, RelationOp(relations: rels, op: Op.all)]);

  DependsOn oneOf(List<Relation> rels) =>
      DependsOn([...operations, RelationOp(relations: rels, op: Op.one)]);

  bool eval(QuestionsListener questionListener) {
    if (operations.isEmpty) return true;

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

    for (final RelationOp relationOp in operations) {
      bool passed = false;
      for (final Relation rel in relationOp.relations) {
        final Response? withId = questionListener.questions[rel.qid];
        final bool relationEval = withId == null
            ? false
            : rel.type == CheckType.exists
                ? true
                : getEquals(rel, withId);
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
    return operations.join("~");
  }

  String toReadableString({required String? Function(String) promptProvider}) {
    String message = "";
    for (final RelationOp op in operations) {
      if (op.relations.length > 1) message += "${op.op.value}: \n";
      for (int i = 0; i < op.relations.length; i++) {
        final Relation relation = op.relations[i];
        final String? questionText = promptProvider(relation.qid);
        if (questionText == null) continue;
        message +=
            "  - ${relation.type == CheckType.exists ? questionText : "$questionText = ${relation.response}}"}${i < op.relations.length - 1 ? "\n" : ""}";
      }
      message += "\n";
    }
    return message;
  }

  static DependsOn fromString(String val) {
    List<RelationOp> ops = val
        .split("~")
        .map((rel) => RelationOp.fromString(rel))
        .whereType<RelationOp>()
        .toList();
    return DependsOn(ops);
  }

  @override
  List<Object?> get props => operations;
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

@immutable
class Baseline {
  const Baseline();
}

@immutable
class RelativeEntry {
  const RelativeEntry();
}

typedef Translator = String? Function(String key, String locale);

extension QuestionYamlLoading on Question {
  static Future<List<Question>> fromYamlAsset(
    BuildContext context,
    String assetPath, {
    Map<String, Map<String, String>>? localizations,
    Translator? translator,
  }) async {
    final yamlString = await rootBundle.loadString(assetPath);
    if (context.mounted) {
      return fromYamlStringInternal(yamlString, context,
          localizations: localizations, translator: translator);
    } else {
      return [];
    }
  }

  static Future<List<Question>> fromYamlFileSystem(
    BuildContext context,
    String filePath, {
    Map<String, Map<String, String>>? localizations,
    Translator? translator,
  }) async {
    final file = File(filePath);
    final yamlString = await file.readAsString();
    if (context.mounted) {
      return fromYamlStringInternal(yamlString, context,
          localizations: localizations, translator: translator);
    } else {
      return [];
    }
  }

  static Future<List<Question>> fromYamlStringInternal(
    String yamlString,
    BuildContext context, {
    Map<String, Map<String, String>>? localizations,
    Translator? translator,
  }) async {
    final doc = loadYaml(yamlString);

    if (doc is! YamlMap) {
      throw ArgumentError('Top level YAML document must be a mapping');
    }

    Map<String, Map<String, String>>? locs = localizations;
    if (locs == null && doc.containsKey('localizations')) {
      locs = <String, Map<String, String>>{};
      final rawLocs = doc['localizations'] as YamlMap;
      rawLocs.forEach((lang, map) {
        locs![lang.toString()] = Map<String, String>.from(map);
      });
    }

    final questionsRaw = doc['questions'];
    if (questionsRaw == null || questionsRaw is! YamlList) {
      throw ArgumentError('YAML must contain a "questions" list');
    }

    final List<Question> questions = [];

    for (final qRaw in questionsRaw) {
      if (qRaw is YamlMap) {
        final map = Map<String, dynamic>.from(qRaw);
        final q = QuestionYamlParsing.fromYamlMap(
          map,
          context,
          localizations: locs,
          translator: translator,
        );
        questions.add(q);
      } else {
        throw ArgumentError('Each question must be a map/object');
      }
    }

    return questions;
  }
}

extension QuestionYamlParsing on Question {
  static Question fromYamlMap(
    Map<String, dynamic> map,
    BuildContext context, {
    Map<String, Map<String, String>>? localizations,
    Translator? translator,
  }) {
    final locale = Localizations.localeOf(context).languageCode;

    String resolveKey(String? key) {
      if (key == null || key.isEmpty) return '';

      if (translator != null) {
        final t = translator(key, locale);
        if (t != null && t.isNotEmpty) return t;
      }
      if (localizations != null) {
        final langMap = localizations[locale];
        if (langMap != null && langMap.containsKey(key)) {
          final val = langMap[key];
          if (val != null && val.isNotEmpty) return val;
        }
      }

      final pretty = key.split('.').last.replaceAll('_', ' ');
      if (pretty.isEmpty) return key;
      return pretty[0].toUpperCase() + pretty.substring(1);
    }

    String stringVal(String k) {
      final v = map[k];
      if (v == null) return '';
      return v.toString();
    }

    bool boolVal(String k, {bool defaultValue = false}) {
      final v = map[k];
      if (v == null) return defaultValue;
      if (v is bool) return v;
      final s = v.toString().toLowerCase();
      return s == 'true' || s == '1';
    }

    num? numVal(String k) {
      final v = map[k];
      if (v == null) return null;
      if (v is num) return v;
      return num.tryParse(v.toString());
    }

    List<String> listOfStrings(dynamic maybeList) {
      if (maybeList == null) return <String>[];
      if (maybeList is List) {
        return maybeList.map((e) => e.toString()).toList();
      }
      return [maybeList.toString()];
    }

    final id = stringVal('id');
    final domainType = stringVal('type');
    final kindRaw = stringVal('kind').isNotEmpty
        ? stringVal('kind')
        : stringVal('questionType');

    final promptKey =
        map.containsKey('promptKey') ? stringVal('promptKey') : '';
    final rawPrompt = map.containsKey('prompt') ? stringVal('prompt') : '';
    final prompt = promptKey.isNotEmpty ? resolveKey(promptKey) : rawPrompt;

    final isRequired = boolVal('isRequired', defaultValue: false);
    final enabled = boolVal('enabled', defaultValue: true);
    final locked = boolVal('locked', defaultValue: false);
    final userCreated = boolVal('userCreated', defaultValue: false);
    final isAddition = boolVal('isAddition', defaultValue: false);
    final deleted = boolVal('deleted', defaultValue: false);

    final kind = kindRaw.trim().toLowerCase();

    if (kind == 'm') {
      final choiceKeys = listOfStrings(map['choices']);
      final localizedChoices = choiceKeys.map((k) {
        return resolveKey(k);
      }).toList();

      return MultipleChoice(
        id: id,
        prompt: prompt,
        type: domainType,
        choices: localizedChoices,
        isRequired: isRequired,
        enabled: enabled,
        locked: locked,
        userCreated: userCreated,
        isAddition: isAddition,
        deleted: deleted,
      );
    } else if (kind == 'a') {
      final choiceKeys = listOfStrings(map['choices']);
      final localizedChoices = choiceKeys.map((k) => resolveKey(k)).toList();

      return AllThatApply(
        id: id,
        prompt: prompt,
        type: domainType,
        choices: localizedChoices,
        isRequired: isRequired,
        enabled: enabled,
        locked: locked,
        userCreated: userCreated,
        isAddition: isAddition,
        deleted: deleted,
      );
    } else if (kind == 'f') {
      return FreeResponse(
        id: id,
        prompt: prompt,
        type: domainType,
        isRequired: isRequired,
        enabled: enabled,
        locked: locked,
        userCreated: userCreated,
        isAddition: isAddition,
        deleted: deleted,
      );
    } else if (kind == 's') {
      final min = numVal('min');
      final max = numVal('max');

      return Numeric(
        id: id,
        prompt: prompt,
        type: domainType,
        min: min,
        max: max,
        isRequired: isRequired,
        enabled: enabled,
        locked: locked,
        userCreated: userCreated,
        isAddition: isAddition,
        deleted: deleted,
      );
    } else {
      return Check(
        id: id,
        prompt: prompt,
        type: domainType,
        isRequired: isRequired,
        enabled: enabled,
        locked: locked,
        userCreated: userCreated,
        isAddition: isAddition,
        deleted: deleted,
      );
    }
  }

  static Question fromYamlString(
    String yamlString,
    BuildContext context, {
    Map<String, Map<String, String>>? localizations,
    Translator? translator,
  }) {
    final parsed = loadYaml(yamlString);
    if (parsed is! YamlMap) {
      throw ArgumentError(
          'Provided YAML string must be a mapping at top level');
    }
    final map = <String, dynamic>{};
    for (final key in parsed.keys) {
      map[key.toString()] = parsed[key];
    }
    return fromYamlMap(map, context,
        localizations: localizations, translator: translator);
  }
}
