import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_resolver.dart';

void main() {
  group('QuestionResolver.resolveFromBaseline', () {
    test('returns original question if transform is null', () {
      final question = MultipleChoice(
        id: 'q2',
        prompt: 'Select One',
        type: 'm',
        choices: [],
        fromBaseline: 'true',
      );
      final response = NumericResponse(
        question: Numeric(id: 'q1', prompt: 'Val', type: 's'),
        stamp: 1,
        response: 5,
      );

      final resolved = question.resolveFromBaseline(baseline: response);
      expect(resolved.length, 1);
      expect(resolved.first, equals(question));
    });

    test('populates choices from OpenResponse in ResponseWrap', () {
      final transform = jsonEncode({'sourceId': 'q1', 'type': 'mapChoices'});
      final question = MultipleChoice(
        id: 'q2',
        prompt: 'Select One',
        type: 'm',
        choices: [],
        fromBaseline: 'true',
        transform: transform,
      );

      final q1 = FreeResponse(id: 'q1', prompt: 'Type', type: 'f');
      final r1 = OpenResponse(question: q1, stamp: 1, response: 'Seizure A');
      final r2 = OpenResponse(question: q1, stamp: 2, response: 'Seizure B');

      final baseline = DetailResponse(
        responses: [r1, r2],
        stamp: 1,
        detailType: 'Detail',
      );

      final resolved = question.resolveFromBaseline(baseline: baseline);

      expect(resolved.length, 1);
      expect(resolved.first, isA<MultipleChoice>());
      final resolvedMc = resolved.first as MultipleChoice;
      expect(resolvedMc.choices, contains('Seizure A'));
      expect(resolvedMc.choices, contains('Seizure B'));
      expect(resolvedMc.choices.length, 2);
    });

    test('populates choices from single OpenResponse using mapChoices', () {
      final transform = jsonEncode({'sourceId': 'q1', 'type': 'mapChoices'});
      final question = MultipleChoice(
        id: 'q2',
        prompt: 'Select One',
        type: 'm',
        choices: [],
        fromBaseline: 'true',
        transform: transform,
      );

      final q1 = FreeResponse(id: 'q1', prompt: 'Type', type: 'f');
      final baseline =
          OpenResponse(question: q1, stamp: 1, response: 'Seizure A');

      final resolved = question.resolveFromBaseline(baseline: baseline);

      expect(resolved.length, 1);
      expect(resolved.first, isA<MultipleChoice>());
      final resolvedMc = resolved.first as MultipleChoice;
      expect(resolvedMc.choices, ['Seizure A']);
    });

    test('replaces [value] in prompt using copyValue', () {
      final transform = jsonEncode({'sourceId': 'q1', 'type': 'copyValue'});
      final question = FreeResponse(
        id: 'q2',
        prompt: 'How was [value]?',
        type: 'f',
        fromBaseline: 'true',
        transform: transform,
      );

      final q1 = FreeResponse(id: 'q1', prompt: 'Type', type: 'f');
      final baseline =
          OpenResponse(question: q1, stamp: 1, response: 'Seizure A');

      final resolved = question.resolveFromBaseline(baseline: baseline);

      expect(resolved.length, 1);
      expect(resolved.first, isA<FreeResponse>());
      final resolvedFr = resolved.first as FreeResponse;
      expect(resolvedFr.prompt, 'How was Seizure A?');
    });
  });

  group('QuestionResolver.resolve', () {
    test('returns original question in list if transform is null', () {
      final question = MultipleChoice(
        id: 'q2',
        prompt: 'Select One',
        type: 'm',
        choices: ['A', 'B'],
      );
      final response = NumericResponse(
        question: Numeric(id: 'q1', prompt: 'Val', type: 's'),
        stamp: 1,
        response: 5,
      );

      final resolved = question.resolve(current: response);
      expect(resolved.length, 1);
      expect(resolved.first, equals(question));
    });

    test('generateForEach creates question for each AllThatApply choice', () {
      final parentQuestion = AllThatApply(
        id: 'seizure-types',
        prompt: 'What seizure types?',
        type: 'test',
        choices: ['Tonic-clonic', 'Absence', 'Focal'],
      );
      final parentResponse = AllResponse(
        question: parentQuestion,
        stamp: 1,
        responses: [0, 2], // Tonic-clonic, Focal
      );

      final transform =
          jsonEncode({'sourceId': 'seizure-types', 'type': 'generateForEach'});
      final followUp = MultipleChoice(
        id: 'seizure-freq',
        prompt: 'How often do you experience {value}?',
        type: 'test',
        choices: ['Daily', 'Weekly', 'Monthly'],
        transform: transform,
      );

      final generated = followUp.resolve(current: parentResponse);

      expect(generated.length, 2);
      expect(generated[0].prompt, 'How often do you experience Tonic-clonic?');
      expect(generated[0].id, 'seizure-freq::tonic-clonic');
      expect(generated[1].prompt, 'How often do you experience Focal?');
      expect(generated[1].id, 'seizure-freq::focal');
    });

    test('generateForEach creates question for MultipleChoice response', () {
      final parentQuestion = MultipleChoice(
        id: 'pain-location',
        prompt: 'Where is the pain?',
        type: 'test',
        choices: ['Head', 'Stomach', 'Back'],
      );
      final parentResponse = MultiResponse(
        question: parentQuestion,
        stamp: 1,
        index: 1, // Stomach
      );

      final transform =
          jsonEncode({'sourceId': 'pain-location', 'type': 'generateForEach'});
      final followUp = Numeric(
        id: 'pain-severity',
        prompt: 'Rate your {value} pain (1-10)',
        type: 'test',
        min: 1,
        max: 10,
        transform: transform,
      );

      final generated = followUp.resolve(current: parentResponse);

      expect(generated.length, 1);
      expect(generated[0].prompt, 'Rate your Stomach pain (1-10)');
      expect(generated[0].id, 'pain-severity::stomach');
    });

    test('generateForEach returns original when source not found', () {
      final parentQuestion = AllThatApply(
        id: 'other-question',
        prompt: 'Other?',
        type: 'test',
        choices: ['X', 'Y'],
      );
      final parentResponse = AllResponse(
        question: parentQuestion,
        stamp: 1,
        responses: [0],
      );

      final transform =
          jsonEncode({'sourceId': 'non-existent', 'type': 'generateForEach'});
      final followUp = MultipleChoice(
        id: 'follow-up',
        prompt: 'Question about {value}?',
        type: 'test',
        choices: ['A', 'B'],
        transform: transform,
      );

      final generated = followUp.resolve(current: parentResponse);

      // Now returns original question when source not found
      expect(generated.length, 1);
      expect(generated.first, equals(followUp));
    });

    test('generateForEach works with ResponseWrap', () {
      final parentQuestion = AllThatApply(
        id: 'seizure-types',
        prompt: 'What seizure types?',
        type: 'test',
        choices: ['Tonic-clonic', 'Absence', 'Focal'],
      );
      final parentResponse = AllResponse(
        question: parentQuestion,
        stamp: 1,
        responses: [1], // Absence
      );

      final detailResponse = DetailResponse(
        responses: [parentResponse],
        stamp: 1,
        detailType: 'Detail',
      );

      final transform =
          jsonEncode({'sourceId': 'seizure-types', 'type': 'generateForEach'});
      final followUp = MultipleChoice(
        id: 'seizure-freq',
        prompt: 'How often {value}?',
        type: 'test',
        choices: ['Daily', 'Weekly'],
        transform: transform,
      );

      final generated = followUp.resolve(current: detailResponse);

      expect(generated.length, 1);
      expect(generated[0].prompt, 'How often Absence?');
    });

    test('mapChoices works with resolve (current recording)', () {
      final transform = jsonEncode({'sourceId': 'q1', 'type': 'mapChoices'});
      final question = MultipleChoice(
        id: 'q2',
        prompt: 'Select One',
        type: 'm',
        choices: [],
        transform: transform,
      );

      final q1 = AllThatApply(
        id: 'q1',
        prompt: 'Type',
        type: 'ata',
        choices: ['Option A', 'Option B', 'Option C'],
      );
      final current = AllResponse(
        question: q1,
        stamp: 1,
        responses: [0, 2], // Option A, Option C
      );

      final resolved = question.resolve(current: current);

      expect(resolved.length, 1);
      expect(resolved.first, isA<MultipleChoice>());
      final resolvedMc = resolved.first as MultipleChoice;
      expect(resolvedMc.choices, ['Option A', 'Option C']);
    });

    test('generateForEach with inline generated definition', () {
      final transform = jsonEncode({
        'type': 'generateForEach',
        'generated': {
          'prompt': 'How often do you experience {value}?',
          'type': 'MultipleChoice',
          'choices': ['Daily', 'Weekly', 'Monthly'],
          'isRequired': true,
        }
      });
      final parentQuestion = AllThatApply(
        id: 'seizure-types',
        prompt: 'What seizure types?',
        type: 'test',
        choices: ['Tonic-clonic', 'Absence'],
        transform: transform,
      );
      final parentResponse = AllResponse(
        question: parentQuestion,
        stamp: 1,
        responses: [0, 1], // Tonic-clonic, Absence
      );

      final detailResponse = DetailResponse(
        responses: [parentResponse],
        stamp: 1,
        detailType: 'Detail',
      );

      final generated = parentQuestion.resolve(current: detailResponse);

      expect(generated.length, 2);

      // First generated question
      expect(generated[0], isA<MultipleChoice>());
      expect(generated[0].prompt, 'How often do you experience Tonic-clonic?');
      expect(generated[0].id, 'seizure-types::tonic-clonic');
      expect((generated[0] as MultipleChoice).choices,
          ['Daily', 'Weekly', 'Monthly']);
      expect(generated[0].requirement, true);

      // Second generated question
      expect(generated[1], isA<MultipleChoice>());
      expect(generated[1].prompt, 'How often do you experience Absence?');
      expect(generated[1].id, 'seizure-types::absence');
    });

    test('generateForEach inline generates Numeric questions', () {
      final transform = jsonEncode({
        'type': 'generateForEach',
        'generated': {
          'prompt': 'Rate {value} severity (1-10)',
          'type': 'Numeric',
          'min': 1,
          'max': 10,
        }
      });
      final parentQuestion = AllThatApply(
        id: 'symptoms',
        prompt: 'Select symptoms',
        type: 'test',
        choices: ['Pain', 'Fatigue'],
        transform: transform,
      );
      final parentResponse = AllResponse(
        question: parentQuestion,
        stamp: 1,
        responses: [0], // Pain
      );

      final detailResponse = DetailResponse(
        responses: [parentResponse],
        stamp: 1,
        detailType: 'Detail',
      );

      final generated = parentQuestion.resolve(current: detailResponse);

      expect(generated.length, 1);
      expect(generated[0], isA<Numeric>());
      expect(generated[0].prompt, 'Rate Pain severity (1-10)');
      final numeric = generated[0] as Numeric;
      expect(numeric.min, 1);
      expect(numeric.max, 10);
    });
  });
}
