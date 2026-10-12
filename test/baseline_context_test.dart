import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_resolver.dart';

void main() {
  group('baselineContext serialization', () {
    test('round-trips through toJson/fromJson', () {
      const question = MultipleChoice(
        id: 'seizure-types-changed',
        prompt: 'Which types changed?',
        type: 'Seizure',
        choices: ['Tonic-clonic', 'Absence'],
        fromBaseline: 'SeizureBaseline',
        baselineContext: ['seizure-types', 'seizure-frequency'],
      );

      final json = question.toJson();
      expect(json['baselineContext'], isNotNull);

      final restored = Question.fromJson(json);
      expect(restored, isA<MultipleChoice>());
      expect(restored.baselineContext, ['seizure-types', 'seizure-frequency']);
      expect(restored.fromBaseline, 'SeizureBaseline');
    });

    test('null baselineContext round-trips correctly', () {
      const question = Check(
        id: 'q1',
        prompt: 'Test',
        type: 'test',
      );

      final json = question.toJson();
      expect(json['baselineContext'], isNull);

      final restored = Question.fromJson(json);
      expect(restored.baselineContext, isNull);
    });

    test('preserves through FreeResponse copyWith', () {
      const question = FreeResponse(
        id: 'q1',
        prompt: 'How is {value}?',
        type: 'test',
        baselineContext: ['baseline-severity'],
      );

      final copied = question.copyWith(prompt: 'Updated?');
      expect(copied.baselineContext, ['baseline-severity']);
      expect(copied.prompt, 'Updated?');
    });

    test('preserves through Numeric copyWith', () {
      const question = Numeric(
        id: 'q1',
        prompt: 'Rate it',
        type: 'test',
        min: 0,
        max: 10,
        baselineContext: ['baseline-freq'],
      );

      final copied = question.copyWith(min: 1);
      expect(copied.baselineContext, ['baseline-freq']);
      expect(copied.min, 1);
    });

    test('preserves through Check copyWith', () {
      const question = Check(
        id: 'q1',
        prompt: 'Confirm',
        type: 'test',
        baselineContext: ['baseline-check'],
      );

      final copied = question.copyWith(prompt: 'Reconfirm');
      expect(copied.baselineContext, ['baseline-check']);
    });

    test('preserves through MultipleChoice copyWith', () {
      const question = MultipleChoice(
        id: 'q1',
        prompt: 'Pick one',
        type: 'test',
        choices: ['A', 'B'],
        baselineContext: ['baseline-mc'],
      );

      final copied = question.copyWith(choices: ['A', 'B', 'C']);
      expect(copied.baselineContext, ['baseline-mc']);
      expect(copied.choices.length, 3);
    });

    test('preserves through AllThatApply copyWith', () {
      const question = AllThatApply(
        id: 'q1',
        prompt: 'Select all',
        type: 'test',
        choices: ['X', 'Y'],
        baselineContext: ['baseline-ata'],
      );

      final copied = question.copyWith(choices: ['X', 'Y', 'Z']);
      expect(copied.baselineContext, ['baseline-ata']);
      expect(copied.choices.length, 3);
    });

    test('can be overridden in copyWith', () {
      const question = FreeResponse(
        id: 'q1',
        prompt: 'Test',
        type: 'test',
        baselineContext: ['old-ref'],
      );

      final copied =
          question.copyWith(baselineContext: ['new-ref-a', 'new-ref-b']);
      expect(copied.baselineContext, ['new-ref-a', 'new-ref-b']);
    });
  });

  group('baselineContext with resolveFromBaseline', () {
    test('baselineContext is preserved through resolveFromBaseline', () {
      final transform =
          jsonEncode({'sourceId': 'seizure-types', 'type': 'mapChoices'});
      final question = AllThatApply(
        id: 'seizure-types-changed',
        prompt: 'Which seizure types have changed?',
        type: 'Seizure',
        choices: const [],
        fromBaseline: 'SeizureBaseline',
        baselineContext: const ['seizure-types', 'seizure-frequency'],
        transform: transform,
      );

      const baselineQuestion = AllThatApply(
        id: 'seizure-types',
        prompt: 'Select types',
        type: 'Seizure',
        choices: ['Type A', 'Type B'],
      );

      final baselineResp = AllResponse(
        question: baselineQuestion,
        stamp: 1,
        responses: const [0, 1],
      );

      final baseline = DetailResponse(
        responses: [baselineResp],
        stamp: 1,
        detailType: 'SeizureBaseline',
      );

      final resolved = question.resolveFromBaseline(baseline: baseline);

      expect(resolved.length, 1);
      final resolvedQ = resolved.first as AllThatApply;
      expect(resolvedQ.choices, ['Type A', 'Type B']);
      // baselineContext is on the original question for UI lookup —
      // transforms don't propagate it (it's metadata for the template)
      expect(question.baselineContext, ['seizure-types', 'seizure-frequency']);
    });
  });

  group('parseBaselineContext', () {
    test('parses from List', () {
      expect(
        Question.parseBaselineContext(['a', 'b']),
        ['a', 'b'],
      );
    });

    test('parses from JSON string', () {
      expect(
        Question.parseBaselineContext('["a","b"]'),
        ['a', 'b'],
      );
    });

    test('returns null for null', () {
      expect(Question.parseBaselineContext(null), isNull);
    });

    test('returns null for invalid string', () {
      expect(Question.parseBaselineContext('not json'), isNull);
    });
  });

  group('equality includes baselineContext', () {
    test('questions with different baselineContext are not equal', () {
      final q1 = Check(
        id: 'q1',
        prompt: 'Test',
        type: 'test',
        baselineContext: ['ref-a'],
      );
      final q2 = Check(
        id: 'q1',
        prompt: 'Test',
        type: 'test',
        baselineContext: ['ref-b'],
      );
      expect(q1, isNot(equals(q2)));
    });

    test('questions with same baselineContext are equal', () {
      final q1 = Check(
        id: 'q1',
        prompt: 'Test',
        type: 'test',
        baselineContext: ['ref-a'],
      );
      final q2 = Check(
        id: 'q1',
        prompt: 'Test',
        type: 'test',
        baselineContext: ['ref-a'],
      );
      expect(q1, equals(q2));
    });
  });
}
