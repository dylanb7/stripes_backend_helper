import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';

class _TestQuestionHome extends QuestionHome {
  _TestQuestionHome(Map<String, Question> qMap) {
    all = qMap;
  }

  @override
  Map<String, List<Question>> byType() => {};
}

void main() {
  const q1 = FreeResponse(id: 'q1', prompt: 'Prompt 1', type: 'f');
  const q2 = Numeric(id: 'q2', prompt: 'Prompt 2', type: 's');
  final stamp = DateTime.now().millisecondsSinceEpoch;

  final mockHome = _TestQuestionHome({'q1': q1, 'q2': q2});

  group('SessionData Serialization', () {
    test('serializes and deserializes correctly', () {
      final data = SessionData(
        editId: 'edit-123',
        submitTime: DateTime(2026, 7, 29, 12, 0),
        description: 'Test description',
        tried: true,
        responses: {
          'q1': OpenResponse(response: 'hello', question: q1, stamp: stamp),
          'q2': NumericResponse(response: 42, question: q2, stamp: stamp),
        },
      );

      final json = data.toJson();
      final deserialized = SessionData.fromJson(json, mockHome);

      expect(deserialized.editId, equals('edit-123'));
      expect(
        deserialized.submitTime,
        equals(DateTime(2026, 7, 29, 12, 0).toUtc()),
      );
      expect(deserialized.submitTime!.isUtc, isTrue);
      expect(deserialized.description, equals('Test description'));
      expect(deserialized.tried, isTrue);
      expect(deserialized.responses.length, equals(2));

      final r1 = deserialized.responses['q1'] as OpenResponse?;
      expect(r1, isNotNull);
      expect(r1!.response, equals('hello'));

      final r2 = deserialized.responses['q2'] as NumericResponse?;
      expect(r2, isNotNull);
      expect(r2!.response, equals(42));
    });

    test('handles null fields gracefully', () {
      const data = SessionData();
      final json = data.toJson();
      final deserialized = SessionData.fromJson(json, mockHome);

      expect(deserialized.editId, isNull);
      expect(deserialized.submitTime, isNull);
      expect(deserialized.description, isNull);
      expect(deserialized.tried, isFalse);
      expect(deserialized.responses, isEmpty);
    });
  });
}
