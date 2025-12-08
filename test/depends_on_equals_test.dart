import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_repo_base.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_listener.dart';

void main() {
  group('DependsOn equals relationship', () {
    test('equals with slider (numeric) response passes when matching', () {
      final numericQuestion =
          Numeric(id: 'q1', prompt: 'Rating', type: 'num', min: 1, max: 10);
      final numericResponse =
          NumericResponse(question: numericQuestion, stamp: 1, response: 5);

      final listener = QuestionsListener();
      listener.addResponse(numericResponse);

      final dependsOn = DependsOn.init().oneOf([
        Relation.equals(
            qid: 'q1', questionType: QuestionType.slider, response: 5),
      ]);

      expect(dependsOn.eval(listener), true);
    });

    test('equals with slider (numeric) response fails when not matching', () {
      final numericQuestion =
          Numeric(id: 'q1', prompt: 'Rating', type: 'num', min: 1, max: 10);
      final numericResponse =
          NumericResponse(question: numericQuestion, stamp: 1, response: 3);

      final listener = QuestionsListener();
      listener.addResponse(numericResponse);

      final dependsOn = DependsOn.init().oneOf([
        Relation.equals(
            qid: 'q1', questionType: QuestionType.slider, response: 5),
      ]);

      expect(dependsOn.eval(listener), false);
    });

    test('equals with freeResponse (text) passes when matching', () {
      final freeQuestion = FreeResponse(id: 'q2', prompt: 'Name', type: 'free');
      final openResponse =
          OpenResponse(question: freeQuestion, stamp: 1, response: 'TestValue');

      final listener = QuestionsListener();
      listener.addResponse(openResponse);

      final dependsOn = DependsOn.init().oneOf([
        Relation.equals(
            qid: 'q2',
            questionType: QuestionType.freeResponse,
            response: 'TestValue'),
      ]);

      expect(dependsOn.eval(listener), true);
    });

    test('equals with freeResponse (text) fails when not matching', () {
      final freeQuestion = FreeResponse(id: 'q2', prompt: 'Name', type: 'free');
      final openResponse = OpenResponse(
          question: freeQuestion, stamp: 1, response: 'DifferentValue');

      final listener = QuestionsListener();
      listener.addResponse(openResponse);

      final dependsOn = DependsOn.init().oneOf([
        Relation.equals(
            qid: 'q2',
            questionType: QuestionType.freeResponse,
            response: 'TestValue'),
      ]);

      expect(dependsOn.eval(listener), false);
    });

    test('equals with multipleChoice passes when matching index', () {
      final mcQuestion = MultipleChoice(
          id: 'q3', prompt: 'Choose', type: 'mc', choices: ['A', 'B', 'C']);
      final multiResponse =
          MultiResponse(question: mcQuestion, stamp: 1, index: 1); // 'B'

      final listener = QuestionsListener();
      listener.addResponse(multiResponse);

      final dependsOn = DependsOn.init().oneOf([
        Relation.equals(
            qid: 'q3', questionType: QuestionType.multipleChoice, response: 1),
      ]);

      expect(dependsOn.eval(listener), true);
    });

    test('equals with allThatApply passes when matching responses', () {
      final ataQuestion = AllThatApply(
          id: 'q4',
          prompt: 'Select all',
          type: 'ata',
          choices: ['X', 'Y', 'Z']);
      final allResponse = AllResponse(
          question: ataQuestion, stamp: 1, responses: [0, 2]); // 'X', 'Z'

      final listener = QuestionsListener();
      listener.addResponse(allResponse);

      final dependsOn = DependsOn.init().oneOf([
        Relation.equals(
            qid: 'q4',
            questionType: QuestionType.allThatApply,
            response: [0, 2]),
      ]);

      expect(dependsOn.eval(listener), true);
    });
  });
}
