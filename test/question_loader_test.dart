import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_repo_base.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_loader.dart';

void main() {
  group('Question Loader', () {
    test('loadInQuestions parses FreeResponse correctly', () {
      final yamlString = '''
questions:
  - id: seizure-q4
    promptKey: seizure.q4.medication_names
    type: category.SEIZURE_BASELINE
    kind: FreeResponse
    isBaseline: true
''';
      final yamlData = loadYaml(yamlString);
      final questionsYaml = yamlData['questions'] as YamlList;

      final questions = loadInQuestions(
        questionsYaml: questionsYaml,
        baselineIds: {'seizure-q4'},
      );

      expect(questions.length, 1);
      expect(questions.first, isA<FreeResponse>());
      expect(questions.first.id, 'seizure-q4');
      expect(questions.first.isBaseline, true);
    });

    test('loadInQuestions parses MultipleChoice correctly', () {
      final yamlString = '''
questions:
  - id: seizure-q1
    promptKey: seizure.q1.had_seizures_past_2_years
    type: category.SEIZURE_BASELINE
    isRequired: true
    kind: MultipleChoice
    choices:
      - common.yes
      - common.no
''';
      final yamlData = loadYaml(yamlString);
      final questionsYaml = yamlData['questions'] as YamlList;

      final questions = loadInQuestions(
        questionsYaml: questionsYaml,
        baselineIds: {'seizure-q1'},
      );

      expect(questions.length, 1);
      expect(questions.first, isA<MultipleChoice>());
      final mc = questions.first as MultipleChoice;
      expect(mc.choices.length, 2);
      expect(mc.isRequired, true);
    });

    test('loadInRecordPaths parses isBaseline correctly', () {
      final yamlString = '''
recordPaths:
  - name: category.SEIZURE_BASELINE
    isBaseline: true
    pages:
      - questionIds: [seizure-q1]
      - questionIds: [seizure-q2]
        dependsOn:
          oneOf:
            - exists: seizure-q1
''';
      final yamlData = loadYaml(yamlString);
      final recordPathsYaml = yamlData['recordPaths'] as YamlList;

      final recordPaths = loadInRecordPaths(recordPathsYaml: recordPathsYaml);

      expect(recordPaths.length, 1);
      expect(recordPaths.first.isBaseline, true);
      expect(recordPaths.first.pages.length, 2);
      expect(recordPaths.first.pages[1].dependsOn.operations.isNotEmpty, true);
    });
  });
}
