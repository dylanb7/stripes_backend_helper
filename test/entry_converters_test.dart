import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_backend_helper/RepositoryBase/EntryBase/entry.dart';
import 'package:stripes_backend_helper/RepositoryBase/EntryBase/entry_converters.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_repo_base.dart';
import 'package:stripes_backend_helper/RepositoryBase/TestBase/BlueDye/blue_dye_impl.dart';

import 'package:stripes_backend_helper/RepositoryBase/TestBase/BlueDye/bm_test_log.dart';

class MockQuestionHome extends QuestionHome {
  final List<Question> questions;

  MockQuestionHome({required this.questions}) {
    for (final q in questions) {
      all[q.id] = q;
    }
  }

  @override
  Map<String, List<Question>> byType() => {};
}

void main() {
  group('Entry Converters Tests', () {
    late MockQuestionHome mockHome;

    setUp(() {
      const q1 = FreeResponse(
        id: 'q1',
        prompt: 'Prompt 1',
        type: 'category.BM',
      );
      const q2 = Numeric(id: 'q2', prompt: 'Prompt 2', type: 'category.BM');
      const q3 = Check(id: 'q3', prompt: 'Prompt 3', type: 'category.BM');
      mockHome = MockQuestionHome(questions: [q1, q2, q3]);
    });

    test('DetailResponse <-> Entry round-trip', () {
      final detail = DetailResponse(
        id: '123',
        group: 'groupA',
        linkingId: 'session-123',
        stamp: 1000000,
        detailType: 'Bowel Movement',
        description: 'Test bowel movement log',
        responses: [
          OpenResponse(
            question: const FreeResponse(
              id: 'q1',
              prompt: 'Prompt 1',
              type: 'category.BM',
            ),
            stamp: 1000000,
            response: 'Very good',
            id: 'res1',
          ),
          NumericResponse(
            question: const Numeric(
              id: 'q2',
              prompt: 'Prompt 2',
              type: 'category.BM',
            ),
            stamp: 1000000,
            response: 5,
            id: 'res2',
          ),
          Selected(
            question: const Check(
              id: 'q3',
              prompt: 'Prompt 3',
              type: 'category.BM',
            ),
            stamp: 1000000,
            id: 'res3',
          ),
        ],
      );

      // Convert to Entry using extension method
      final entry = detail.toEntry('user123');
      expect(entry.id, '123');
      expect(entry.subUserId, 'user123');
      expect(entry.group, 'groupA');
      expect(entry.sessionId, 'session-123');
      expect(entry.entityType, InputCategory.event.name);
      expect(entry.category, InputCategory.event);
      expect(entry.subtype, 'Bowel Movement');

      // Convert back using extension method
      final reconstructed = entry.toDetailResponse(mockHome);
      expect(reconstructed.id, detail.id);
      expect(reconstructed.group, detail.group);
      expect(reconstructed.linkingId, detail.linkingId);
      expect(reconstructed.stamp, detail.stamp);
      expect(reconstructed.description, detail.description);
      expect(reconstructed.type, 'Bowel Movement');
      expect(reconstructed.responses.length, 3);

      final openRes = reconstructed.responses[0] as OpenResponse;
      expect(openRes.response, 'Very good');
      expect(openRes.question.id, 'q1');

      final numRes = reconstructed.responses[1] as NumericResponse;
      expect(numRes.response, 5);

      final selectedRes = reconstructed.responses[2] as Selected;
      expect(selectedRes.question.id, 'q3');
    });

    test('BlueDye Test Session <-> Entries round-trip', () {
      final startTime = DateTime(2026, 7, 20, 12, 0);
      final finishTime = DateTime(2026, 7, 20, 12, 30);

      final state = BlueDyeState(
        id: 'test_session_1',
        startTime: startTime,
        finishedEating: const Duration(minutes: 30),
        finishedEatingTime: finishTime,
        amountConsumed: AmountConsumed.all,
        logs: [],
      );

      // Convert metadata to test entry
      final testEntry = blueDyeTestToEntry(
        state,
        'user123',
        sessionId: 'session_abc',
      );
      expect(testEntry.entityType, InputCategory.test.name);
      expect(testEntry.category, InputCategory.test);
      expect(testEntry.subtype, 'blue_dye_test');
      expect(testEntry.sessionId, 'session_abc');

      // Convert logs to log entries
      final logDetail = DetailResponse(
        id: 'log1',
        stamp: startTime.add(const Duration(hours: 4)).millisecondsSinceEpoch,
        detailType: 'BM',
        responses: [
          Selected(
            question: const Check(
              id: 'q3',
              prompt: 'Prompt 3',
              type: 'category.BM',
            ),
            stamp: startTime
                .add(const Duration(hours: 4))
                .millisecondsSinceEpoch,
            id: 'res3',
          ),
        ],
      );
      final testLog = BMTestLog(response: logDetail, isBlue: true, id: 'log1');

      final logEntry = bmTestLogToEntry(testLog, 'user123', 'session_abc');
      expect(logEntry.entityType, InputCategory.event.name);
      expect(logEntry.category, InputCategory.event);
      expect(logEntry.subtype, 'BM');
      expect(logEntry.sessionId, 'session_abc');
      expect(logEntry.data['isBlue'], true);

      // Reconstruct BlueDyeResp from the session
      final reconstructedResp = sessionToBlueDyeResp(testEntry, [
        logEntry,
      ], mockHome);
      expect(reconstructedResp.id, 'test_session_1');
      expect(reconstructedResp.startEating.isAtSameMomentAs(startTime), isTrue);
      expect(reconstructedResp.eatingDuration, const Duration(minutes: 30));
      expect(reconstructedResp.amountConsumed, AmountConsumed.all);
      expect(reconstructedResp.logs.length, 1);
      expect(reconstructedResp.logs.first.isBlue, true);
      expect(reconstructedResp.logs.first.response.id, 'log1');
      expect(reconstructedResp.blueBowelMovements, 1);
      expect(reconstructedResp.normalBowelMovements, 0);
    });
  });
}
