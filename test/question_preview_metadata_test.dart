import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_loader.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/transform.dart';
import 'package:yaml/yaml.dart';

const _kinds = [
  'FreeResponse',
  'Numeric',
  'Check',
  'MultipleChoice',
  'AllThatApply',
];

List<Question> _load({String metadata = ''}) => loadInQuestions(
  questionsYaml: loadYaml(
    _kinds
        .map(
          (kind) =>
              '''
- id: question-$kind
  promptKey: question.full
  type: category.example
  kind: $kind
  choices: [choice.one, choice.two]
$metadata
''',
        )
        .join(),
  ) as YamlList,
  baselineIds: {},
);

Question _copy(
  Question question, {
  String? shortPrompt,
  int? previewPriority,
}) => switch (question) {
  FreeResponse() => question.copyWith(
    prompt: 'Updated full prompt',
    shortPrompt: shortPrompt,
    previewPriority: previewPriority,
  ),
  Numeric() => question.copyWith(
    prompt: 'Updated full prompt',
    shortPrompt: shortPrompt,
    previewPriority: previewPriority,
  ),
  Check() => question.copyWith(
    prompt: 'Updated full prompt',
    shortPrompt: shortPrompt,
    previewPriority: previewPriority,
  ),
  MultipleChoice() => question.copyWith(
    prompt: 'Updated full prompt',
    shortPrompt: shortPrompt,
    previewPriority: previewPriority,
  ),
  AllThatApply() => question.copyWith(
    prompt: 'Updated full prompt',
    shortPrompt: shortPrompt,
    previewPriority: previewPriority,
  ),
};

void main() {
  group('Optional question preview metadata', () {
    test('loads shorthand and priority for every YAML question kind', () {
      final questions = _load(
        metadata: '''
  shortPromptKey: '  question.short  '
  previewPriority: 10''',
      );

      expect(questions.map(QuestionType.from).toSet().length, _kinds.length);
      for (final question in questions) {
        expect(question.shortPrompt, 'question.short');
        expect(question.previewPriority, 10);
        expect(question.prompt, 'question.full');
      }
    });

    test('existing YAML and JSON load without preview metadata', () {
      for (final question in _load()) {
        expect(question.shortPrompt, isNull);
        expect(question.previewPriority, isNull);
        final oldJson = question.toJson()
          ..remove('shortPrompt')
          ..remove('previewPriority');
        final restored = Question.fromJson(oldJson);
        expect(restored.shortPrompt, isNull);
        expect(restored.previewPriority, isNull);
        expect(restored, question);
      }
    });

    test('JSON round trips preview metadata for every question kind', () {
      for (final question in _load(
        metadata: '''
  shortPromptKey: question.short
  previewPriority: 0''',
      )) {
        final json = question.toJson();
        expect(json['shortPrompt'], 'question.short');
        expect(json['previewPriority'], 0);
        expect(Question.fromJson(json), question);
      }
    });

    test('copyWith preserves and can update metadata for every kind', () {
      for (final question in _load(
        metadata: '''
  shortPromptKey: question.short
  previewPriority: 10''',
      )) {
        final preserved = _copy(question);
        expect(preserved.shortPrompt, 'question.short');
        expect(preserved.previewPriority, 10);
        final changed = _copy(
          question,
          shortPrompt: 'question.shorter',
          previewPriority: 0,
        );
        expect(changed.shortPrompt, 'question.shorter');
        expect(changed.previewPriority, 0);
        expect(changed.prompt, 'Updated full prompt');
      }
    });

    test('metadata participates in equality for every kind', () {
      for (final question in _load()) {
        final baseline = _copy(question);
        expect(baseline, isNot(_copy(question, shortPrompt: 'Short')));
        expect(baseline, isNot(_copy(question, previewPriority: 10)));
      }
    });

    test('ignores invalid optional YAML metadata without losing questions', () {
      for (final metadata in [
        '  shortPromptKey: "   "\n  previewPriority: 1.5',
        '  shortPromptKey: 123\n  previewPriority: "10"',
        '  shortPromptKey: [one, two]\n  previewPriority: true',
      ]) {
        for (final question in _load(metadata: metadata)) {
          expect(question.shortPrompt, isNull);
          expect(question.previewPriority, isNull);
          expect(question.prompt, 'question.full');
        }
      }
    });

    test('ignores invalid optional JSON metadata for every kind', () {
      for (final question in _load()) {
        for (final (shortPrompt, priority) in [
          ('   ', 1.5),
          (123, '10'),
          (<String>['one'], true),
        ]) {
          final restored = Question.fromJson({
            ...question.toJson(),
            'shortPrompt': shortPrompt,
            'previewPriority': priority,
          });
          expect(restored.shortPrompt, isNull);
          expect(restored.previewPriority, isNull);
        }
      }
    });
  });

  group('Generated question preview metadata', () {
    const template = Check(
      id: 'template',
      prompt: 'full.prompt',
      shortPrompt: 'short.prompt',
      previewPriority: 10,
      type: 'category.example',
    );

    for (final kind in _kinds) {
      test('$kind inherits metadata when using the template prompt', () {
        final generated = GeneratedDefinition(
          questionType: kind,
        ).build(template, 'Example', 'template::example', {'value': 'Example'});
        expect(generated.shortPrompt, 'short.prompt');
        expect(generated.previewPriority, 10);
        expect(generated.interpolations, {'value': 'Example'});
      });

      test('$kind does not reuse shorthand for a different question', () {
        final generated = GeneratedDefinition(
          questionType: kind,
          prompt: 'different.prompt',
        ).build(template, 'Example', 'template::example', {});
        expect(generated.shortPrompt, isNull);
        expect(generated.previewPriority, isNull);
      });

      test('$kind supports explicit generated metadata', () {
        final definition = GeneratedDefinition.fromJson({
          'type': kind,
          'prompt': 'generated.full',
          'shortPromptKey': 'generated.short',
          'previewPriority': 20,
        });
        expect(GeneratedDefinition.fromJson(definition.toJson()), definition);
        final generated = definition.build(
          template,
          'Example',
          'template::example',
          {},
        );
        expect(generated.shortPrompt, 'generated.short');
        expect(generated.previewPriority, 20);
      });
    }
  });
}
