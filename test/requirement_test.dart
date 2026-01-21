import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/condition.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/requirement.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_listener.dart';

class MockListener extends QuestionsListener {
  MockListener(Map<String, Response?> responses) : super() {
    responses.forEach((key, value) {
      if (value != null) {
        questions[key] = value;
      }
    });
  }
}

const q1 = FreeResponse(id: 'q1', prompt: '', type: 'test');
const q2 = Numeric(id: 'q2', prompt: '', type: 'test', min: 0, max: 10);
const q3 = Numeric(id: 'q3', prompt: '', type: 'test', min: 0, max: 10);

const stamp = 123456789;

void main() {
  group('MatchesRegex Condition', () {
    test('matches simple text', () {
      const condition = MatchesRegex('q1', r'^[a-z]+$');

      expect(
          condition.evaluate(
              OpenResponse(response: 'hello', question: q1, stamp: stamp)),
          isTrue);
      expect(
          condition.evaluate(
              OpenResponse(response: '123', question: q1, stamp: stamp)),
          isFalse);
      expect(
          condition.evaluate(
              OpenResponse(response: 'Hello', question: q1, stamp: stamp)),
          isFalse);
      expect(condition.evaluate(null), isFalse);
    });

    test('matches email-like pattern', () {
      const condition = MatchesRegex('q1', r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

      expect(
          condition.evaluate(OpenResponse(
              response: 'test@example.com', question: q1, stamp: stamp)),
          isTrue);
      expect(
          condition.evaluate(OpenResponse(
              response: 'invalid-email', question: q1, stamp: stamp)),
          isFalse);
    });
  });

  group('Requirement Evaluation', () {
    test('evaluates empty requirement as true', () {
      const requirement = Requirement.nothing();
      final listener = MockListener({});

      expect(requirement.eval(listener), isTrue);
    });

    test('evaluates allOf group', () {
      final requirement = const Requirement.nothing().allOf([
        const ExistsCondition('q1'),
        const EqualsExact('q2', 5),
      ]);

      final listener1 = MockListener({
        'q1': OpenResponse(response: 'filled', question: q1, stamp: stamp),
        'q2': NumericResponse(response: 5, question: q2, stamp: stamp),
      });
      expect(requirement.eval(listener1), isTrue);

      final listener2 = MockListener({
        'q1': OpenResponse(response: 'filled', question: q1, stamp: stamp),
        'q2': NumericResponse(response: 10, question: q2, stamp: stamp),
      });
      expect(requirement.eval(listener2), isFalse);
    });

    test('evaluates oneOf group', () {
      final requirement = const Requirement.nothing().oneOf([
        const EqualsExact('q1', 1),
        const EqualsExact('q1', 2),
      ]);

      expect(
          requirement.eval(MockListener({
            'q1': NumericResponse(response: 1, question: q2, stamp: stamp)
          })),
          isTrue);
      expect(
          requirement.eval(MockListener({
            'q1': NumericResponse(response: 2, question: q2, stamp: stamp)
          })),
          isTrue);
      expect(
          requirement.eval(MockListener({
            'q1': NumericResponse(response: 3, question: q2, stamp: stamp)
          })),
          isFalse);
    });

    test('combined groups (AND between groups)', () {
      final requirement = const Requirement.nothing()
          .allOf([const ExistsCondition('q1')]).oneOf(
              [const EqualsExact('q2', 1), const EqualsExact('q2', 2)]);

      // Both must satisfy
      expect(
          requirement.eval(MockListener({
            'q1': OpenResponse(response: 'ok', question: q1, stamp: stamp),
            'q2': NumericResponse(response: 1, question: q2, stamp: stamp),
          })),
          isTrue);

      expect(
          requirement.eval(MockListener({
            'q1': null,
            'q2': NumericResponse(response: 1, question: q2, stamp: stamp),
          })),
          isFalse);

      expect(
          requirement.eval(MockListener({
            'q1': OpenResponse(response: 'ok', question: q1, stamp: stamp),
            'q2': NumericResponse(response: 3, question: q2, stamp: stamp),
          })),
          isFalse);
    });
    group('Requirement Serialization', () {
      test('Requirement Serialization round-trips through string', () {
        final original = const Requirement.nothing().allOf([
          const ExistsCondition('q1'),
          const MatchesRegex('q2', 'abc')
        ]).oneOf([const EqualsExact('q3', 1)]);

        final serialized = original.toString();
        final deserialized = Requirement.fromString(serialized);

        expect(deserialized, equals(original));
      });
    });
  });

  group('Implicit Question ID', () {
    test('matches regex with implicit ID', () {
      final yaml = loadYaml('''
regex: '^[a-z]+\$'
''') as YamlMap;

      final requirement = Requirement.fromYaml(yaml, defaultQuestionId: 'q1');
      expect(
          requirement.eval(MockListener({
            'q1': OpenResponse(response: 'hello', question: q1, stamp: stamp)
          })),
          isTrue);
      expect(
          requirement.eval(MockListener({
            'q1': OpenResponse(response: '123', question: q1, stamp: stamp)
          })),
          isFalse);
    });

    test('exists check with implicit ID (exists: true)', () {
      final yaml = loadYaml('''
exists: true
''') as YamlMap;

      final requirement = Requirement.fromYaml(yaml, defaultQuestionId: 'q1');
      expect(
          requirement.eval(MockListener({
            'q1': OpenResponse(response: 'hello', question: q1, stamp: stamp)
          })),
          isTrue);
      expect(
          requirement.eval(MockListener({
            'q2': NumericResponse(response: 1, question: q2, stamp: stamp)
          })),
          isFalse);
    });

    test('explicit implicit override', () {
      // Yaml specifies implicit ID logic but overrides prompt? No, override ID.
      final yaml = loadYaml('''
questionId: q2
equals: 5
''') as YamlMap;
      // Default is q1, but yaml says q2.
      final requirement = Requirement.fromYaml(yaml, defaultQuestionId: 'q1');

      expect(
          requirement.eval(MockListener({
            'q2': NumericResponse(response: 5, question: q2, stamp: stamp)
          })),
          isTrue);
      expect(
          requirement.eval(MockListener({
            'q1': OpenResponse(response: 'hello', question: q1, stamp: stamp)
          })),
          isFalse);
    });
  });

  group('QuestionsListener Integration', () {
    test('setResponse updates pending state based on requirement', () {
      final listener = QuestionsListener(responses: []);
      // Question with a regex requirement
      final q = FreeResponse(
        id: 'q1',
        prompt: 'Email',
        type: 'text',
        requirement: Requirement([
          ConditionGroup(
              conditions: [MatchesRegex('q1', r'^[\w]+@[\w]+\.com$')],
              op: GroupOp.all)
        ]),
      );

      // 1. Set invalid response
      listener.setResponse(q,
          response:
              OpenResponse(response: 'invalid', question: q, stamp: stamp));
      expect(listener.pending.contains(q), isTrue);

      // 2. Set valid response
      listener.setResponse(q,
          response: OpenResponse(
              response: 'test@example.com', question: q, stamp: stamp));
      expect(listener.pending.contains(q), isFalse);
    });

    test('setResponse removes response from map on null', () {
      final listener = QuestionsListener(responses: []);
      final q = FreeResponse(
          id: 'q1',
          prompt: '',
          type: 'text',
          requirement: Requirement.exists('q1'));

      // Add response
      listener.setResponse(q,
          response: OpenResponse(response: 'a', question: q, stamp: stamp));
      expect(listener.questions.containsKey('q1'), isTrue);
      expect(listener.pending.contains(q), isFalse);

      // Remove response
      listener.setResponse(q, response: null);
      expect(listener.questions.containsKey('q1'), isFalse);
      // specific bug check: removing response from Key('q1') vs Key(Question)

      // Should be pending because Requirement exists
      expect(listener.pending.contains(q), isTrue);
    });
    test('addPendingQuestions convenience method', () {
      final listener = QuestionsListener(responses: []);
      const q1 = FreeResponse(
          id: 'q1',
          prompt: '',
          type: 'text',
          requirement: Requirement.nothing()); // Uses implicit self check
      final q2 = FreeResponse(id: 'q2', prompt: '', type: 'text');
      final q3 = FreeResponse(
          id: 'q3',
          prompt: '',
          type: 'text',
          requirement: Requirement.exists('q3'));

      // q1 is partially filled (simulated by having response but then maybe we check logic)
      // Actually addPendingQuestions checks valid state.
      // q1: required, no response -> INVALID -> add to pending
      // q2: not required, no response -> VALID -> remove from pending
      // q3: required, has response -> VALID -> remove from pending

      listener.questions['q3'] =
          OpenResponse(response: 'filled', question: q3, stamp: stamp);

      listener.addPendingQuestions([q1, q2, q3]);

      expect(listener.pending.contains(q1), isTrue);
      // q2 has no requirement, so it is valid (not pending) even without response
      expect(listener.pending.contains(q2), isFalse);
      expect(listener.pending.contains(q3), isFalse);
    });
  });

  group('New Requirement Factories', () {
    test('Requirement.required() works with implicit context', () {
      const req = Requirement.nothing();
      final listener = MockListener({});
      // No response for 'q1'
      expect(req.eval(listener, contextId: 'q1'), isFalse);

      listener.questions['q1'] =
          OpenResponse(response: 'ok', question: q1, stamp: stamp);
      expect(req.eval(listener, contextId: 'q1'), isTrue);
    });

    test('Requirement.tryMatch() works with implicit context', () {
      final req = Requirement.tryMatch(r'^\d+$');
      final listener = MockListener({});

      listener.questions['q1'] =
          OpenResponse(response: 'abc', question: q1, stamp: stamp);
      expect(req.eval(listener, contextId: 'q1'), isFalse);

      listener.questions['q1'] =
          OpenResponse(response: '123', question: q1, stamp: stamp);
      expect(req.eval(listener, contextId: 'q1'), isTrue);
    });
  });
}
