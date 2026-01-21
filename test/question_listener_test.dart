import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_listener.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_repo_base.dart';

class MockQuestionHome extends QuestionHome {
  @override
  Map<String, List<Question>> byType() => {};

  @override
  Question? fromBank(String id) => all[id];
}

void main() {
  group('QuestionsListener Serialization', () {
    late MockQuestionHome mockHome;
    late FreeResponse qFree;
    late Numeric qNumeric;

    setUp(() {
      mockHome = MockQuestionHome();
      qFree = FreeResponse(id: 'free_q', prompt: 'Tell me', type: 'f');
      qNumeric =
          Numeric(id: 'num_q', prompt: 'Count', type: 'n', min: 0, max: 10);

      mockHome.all['free_q'] = qFree;
      mockHome.all['num_q'] = qNumeric;
    });

    test('serializes and deserializes correctly', () {
      final listener = QuestionsListener(
        editId: 'edit_123',
        submitTime: DateTime(2023, 10, 15, 12, 30),
        description: 'Test Description',
        tried: true,
      );

      final r1 =
          OpenResponse(question: qFree, stamp: 100, response: 'Answer 1');
      final r2 = NumericResponse(question: qNumeric, stamp: 101, response: 5);

      listener.addResponse(r1);
      listener.addResponse(r2);

      final json = listener.toJson();

      // Verify JSON structure
      expect(json['editId'], 'edit_123');
      expect(json['description'], 'Test Description');
      expect(json['tried'], true);
      expect(json['submitTime'], isNotNull);
      expect(json['responses'], hasLength(2));

      // Deserialize
      final deserialized = QuestionsListener.fromJson(json, mockHome);

      expect(deserialized.editId, 'edit_123');
      expect(deserialized.description, 'Test Description');
      expect(deserialized.tried, true);
      expect(deserialized.submitTime, DateTime(2023, 10, 15, 12, 30));
      expect(deserialized.questions.length, 2);

      final res1 = deserialized.questions['free_q'];
      expect(res1, isA<OpenResponse>());
      expect((res1 as OpenResponse).response, 'Answer 1');

      final res2 = deserialized.questions['num_q'];
      expect(res2, isA<NumericResponse>());
      expect((res2 as NumericResponse).response, 5);
    });

    test('handles null fields gracefully', () {
      final listener = QuestionsListener(
        tried: false,
      );
      final json = listener.toJson();

      final deserialized = QuestionsListener.fromJson(json, mockHome);

      expect(deserialized.editId, null);
      expect(deserialized.description, null);
      expect(deserialized.submitTime, null);
      expect(deserialized.tried, false);
      expect(deserialized.questions.isEmpty, true);
    });
  });
}
