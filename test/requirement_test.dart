import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/condition.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/requirement.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/session_data.dart';

SessionData dataWith(Map<String, Response> map) => SessionData(responses: map);

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
          OpenResponse(response: 'hello', question: q1, stamp: stamp),
        ),
        isTrue,
      );
      expect(
        condition.evaluate(
          OpenResponse(response: '123', question: q1, stamp: stamp),
        ),
        isFalse,
      );
      expect(
        condition.evaluate(
          OpenResponse(response: 'Hello', question: q1, stamp: stamp),
        ),
        isFalse,
      );
      expect(condition.evaluate(null), isFalse);
    });

    test('matches email-like pattern', () {
      const condition = MatchesRegex('q1', r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

      expect(
        condition.evaluate(
          OpenResponse(
            response: 'test@example.com',
            question: q1,
            stamp: stamp,
          ),
        ),
        isTrue,
      );
      expect(
        condition.evaluate(
          OpenResponse(response: 'invalid-email', question: q1, stamp: stamp),
        ),
        isFalse,
      );
    });
  });

  group('Requirement Evaluation', () {
    test('evaluates empty requirement as true', () {
      const requirement = Requirement.nothing();
      final data = dataWith({});

      expect(requirement.eval(data), isTrue);
    });

    test('evaluates allOf group', () {
      final requirement = const Requirement.nothing().allOf([
        const ExistsCondition('q1'),
        const EqualsExact('q2', 5),
      ]);

      final data1 = dataWith({
        'q1': OpenResponse(response: 'filled', question: q1, stamp: stamp),
        'q2': NumericResponse(response: 5, question: q2, stamp: stamp),
      });
      expect(requirement.eval(data1), isTrue);

      final data2 = dataWith({
        'q1': OpenResponse(response: 'filled', question: q1, stamp: stamp),
        'q2': NumericResponse(response: 10, question: q2, stamp: stamp),
      });
      expect(requirement.eval(data2), isFalse);
    });

    test('evaluates oneOf group', () {
      final requirement = const Requirement.nothing().oneOf([
        const EqualsExact('q1', 1),
        const EqualsExact('q1', 2),
      ]);

      expect(
        requirement.eval(
          dataWith({
            'q1': NumericResponse(response: 1, question: q2, stamp: stamp),
          }),
        ),
        isTrue,
      );
      expect(
        requirement.eval(
          dataWith({
            'q1': NumericResponse(response: 2, question: q2, stamp: stamp),
          }),
        ),
        isTrue,
      );
      expect(
        requirement.eval(
          dataWith({
            'q1': OpenResponse(response: 'hello', question: q1, stamp: stamp),
          }),
        ),
        isFalse,
      );
    });
  });

  group('New Requirement Factories', () {
    test('Requirement.hasEntry() works with implicit context', () {
      final req = Requirement.hasEntry();
      final emptyData = dataWith({});
      // No response for 'q1'
      expect(req.eval(emptyData, contextId: 'q1'), isFalse);

      final filledData = dataWith({
        'q1': OpenResponse(response: 'ok', question: q1, stamp: stamp),
      });
      expect(req.eval(filledData, contextId: 'q1'), isTrue);
    });

    test('Requirement.tryMatch() works with implicit context', () {
      final req = Requirement.tryMatch(r'^\d+$');

      final invalidData = dataWith({
        'q1': OpenResponse(response: 'abc', question: q1, stamp: stamp),
      });
      expect(req.eval(invalidData, contextId: 'q1'), isFalse);

      final validData = dataWith({
        'q1': OpenResponse(response: '123', question: q1, stamp: stamp),
      });
      expect(req.eval(validData, contextId: 'q1'), isTrue);
    });
  });
}
