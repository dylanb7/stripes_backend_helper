import 'package:flutter/material.dart' hide Transform;
import 'package:flutter/services.dart' show rootBundle;
import 'package:yaml/yaml.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_repo_base.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/transform.dart';

@immutable
class QuestionsYamlData {
  final List<RecordPath> recordPaths;
  final List<Question> questions;
  const QuestionsYamlData({required this.questions, required this.recordPaths});
}

Future<QuestionsYamlData> loadQuestionsAndRecordsFromYaml() async {
  final yamlString = await rootBundle.loadString('lib/assets/questions.yaml');
  final yamlData = loadYaml(yamlString);

  final recordPaths =
      loadInRecordPaths(recordPathsYaml: yamlData["recordPaths"]);

  final Set<String> baselineQuestionIds = {};
  for (final rp in recordPaths) {
    if (rp.isBaseline) {
      for (final page in rp.pages) {
        baselineQuestionIds.addAll(page.questionIds);
      }
    }
  }

  final questions = loadInQuestions(
      questionsYaml: yamlData["questions"], baselineIds: baselineQuestionIds);

  return QuestionsYamlData(questions: questions, recordPaths: recordPaths);
}

List<RecordPath> loadInRecordPaths({
  required YamlList recordPathsYaml,
}) {
  final recordPaths = <RecordPath>[];

  for (final rp in recordPathsYaml) {
    final name = rp['name'] as String;
    final pagesYaml = rp['pages'] as YamlList;
    final pages = <PageLayout>[];

    for (final p in pagesYaml) {
      final questionIds =
          (p['questionIds'] as YamlList?)?.map((e) => e.toString()).toList();
      final headerKey = p['headerKey'] as String?;

      DependsOn? dependsOn;
      if (p['dependsOn'] is YamlMap) {
        dependsOn = DependsOn.fromYaml(p['dependsOn'] as YamlMap);
      }

      pages.add(PageLayout(
        questionIds: questionIds ?? [],
        header: headerKey,
        dependsOn: dependsOn ?? const DependsOn.nothing(),
      ));
    }

    final bool isBaseline = (rp['isBaseline'] == true);

    recordPaths.add(RecordPath(
      name: name,
      pages: pages,
      isBaseline: isBaseline,
    ));
  }

  return recordPaths;
}

List<Question> loadInQuestions({
  required YamlList questionsYaml,
  required Set<String> baselineIds,
}) {
  final questions = <Question>[];

  bool boolVal(dynamic value, {bool defaultValue = false}) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    final s = value.toString().toLowerCase();
    return s == 'true' || s == '1';
  }

  for (final q in questionsYaml) {
    final type = q['type'] as String;
    final String id = q['id'];
    final QuestionType kind = QuestionType.fromString(q['kind']);

    final promptKey = q['promptKey'] as String;

    final bool isRequired = boolVal(q['isRequired']);
    DependsOn dependsOn = const DependsOn.nothing();
    if (q['dependsOn'] is YamlMap) {
      dependsOn = DependsOn.fromYaml(q['dependsOn'] as YamlMap);
    }

    // Parse transform: supports both YamlMap (native YAML) and String (JSON)
    String? transform;
    final transformValue = q["transform"];
    if (transformValue is YamlMap) {
      final parsed = Transform.fromYaml(transformValue);
      transform = parsed?.serialize();
    } else if (transformValue is String) {
      transform = transformValue;
    }

    final bool isBaseline = baselineIds.contains(id);
    final String? fromBaseline = q["fromBaseline"];

    switch (kind) {
      case QuestionType.freeResponse:
        questions.add(FreeResponse(
            id: id,
            prompt: promptKey,
            type: type,
            isRequired: isRequired,
            dependsOn: dependsOn,
            transform: transform,
            isBaseline: isBaseline,
            fromBaseline: fromBaseline));
        break;

      case QuestionType.slider:
        questions.add(Numeric(
            id: id,
            prompt: promptKey,
            type: type,
            min: q['min'],
            max: q['max'],
            isRequired: isRequired,
            dependsOn: dependsOn,
            transform: transform,
            isBaseline: isBaseline,
            fromBaseline: fromBaseline));
        break;

      case QuestionType.check:
        questions.add(Check(
            id: id,
            prompt: promptKey,
            type: type,
            isRequired: isRequired,
            dependsOn: dependsOn,
            transform: transform,
            isBaseline: isBaseline,
            fromBaseline: fromBaseline));
        break;

      case QuestionType.multipleChoice:
      case QuestionType.allThatApply:
        final choices = (q['choices']
            .map<String>((choice) => choice.toString())
            .toList() as List<String>);

        if (kind == QuestionType.multipleChoice) {
          questions.add(MultipleChoice(
              id: id,
              prompt: promptKey,
              type: type,
              choices: choices,
              isRequired: isRequired,
              dependsOn: dependsOn,
              transform: transform,
              isBaseline: isBaseline,
              fromBaseline: fromBaseline));
        } else {
          questions.add(AllThatApply(
              id: id,
              prompt: promptKey,
              type: type,
              choices: choices,
              isRequired: isRequired,
              dependsOn: dependsOn,
              transform: transform,
              isBaseline: isBaseline,
              fromBaseline: fromBaseline));
        }
        break;
    }
  }

  return questions;
}
