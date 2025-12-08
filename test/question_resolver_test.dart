import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_resolver.dart';

void main() {
  group('QuestionResolver', () {
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

      final resolved = question.resolve(response);
      expect(resolved, equals(question));
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

      final resolved = question.resolve(baseline);

      expect(resolved, isA<MultipleChoice>());
      final resolvedMc = resolved as MultipleChoice;
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

      final resolved = question.resolve(baseline);

      expect(resolved, isA<MultipleChoice>());
      final resolvedMc = resolved as MultipleChoice;
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

      final resolved = question.resolve(baseline);

      expect(resolved, isA<FreeResponse>());
      final resolvedFr = resolved as FreeResponse;
      expect(resolvedFr.prompt, 'How was Seizure A?');
    });
  });
}
