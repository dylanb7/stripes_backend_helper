import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_backend_helper/RepositoryBase/EntryBase/entry.dart';
import 'package:stripes_backend_helper/RepositoryBase/ModularTestBase/test_definition.dart';
import 'package:stripes_backend_helper/RepositoryBase/ModularTestBase/test_engine.dart';
import 'package:stripes_backend_helper/RepositoryBase/ModularTestBase/test_loader.dart';

class BlueMealEatenRule extends TestTriggerStrategy {
  @override
  Future<bool> shouldTrigger({
    required Entry currentResponse,
    required List<Entry> historicalResponses,
    required ActiveTestProtocol testState,
  }) async {
    return currentResponse.data['blue_meal_percentage'] == '100%';
  }
}

class FirstBrownAfterBlueRunRule extends TestTriggerStrategy {
  @override
  Future<bool> shouldTrigger({
    required Entry currentResponse,
    required List<Entry> historicalResponses,
    required ActiveTestProtocol testState,
  }) async {
    return currentResponse.data['bm_color'] == 'brown' ||
        currentResponse.data['bm_color'] == 'blue';
  }
}

void main() {
  group('YAML Test Protocol Parsing with Strategy Registry', () {
    const yamlString = '''
tests:
  - id: blue_meal_transit
    name: "Blue Meal Transit Test"
    listensTo:
      - "Meal Entry"
      - "Bowel Movements"
    stages:
      - id: eat_meal
        injections:
          recordPath: "Meal Entry"
          placement: page
          pageIndex: 0
          questionIds:
            - "blue_meal_percentage"
            - "blue_meal_duration"
        triggers:
          - strategy: "BlueMealEatenRule"
            nextStage: awaiting_transit

      - id: awaiting_transit
        injections:
          recordPath: "Bowel Movements"
          placement: review
          questionIds:
            - "bm_color"
        triggers:
          - strategy: "FirstBrownAfterBlueRunRule"
            action: schedule_review
            nextStage: completed
            reviewNotification:
              titleKey: "Test Verification Required"
              bodyKey: "Please review bowel movement record before completing test."
              delayMinutes: 5

      - id: completed
        isTerminal: true
''';

    test('should parse YAML stage triggers with Strategy, TriggerAction, and NotificationConfig', () {
      final definitions = loadTestDefinitionsFromYaml(yamlString);
      expect(definitions.length, equals(1));

      final testDef = definitions.first;
      final stage2 = testDef.stages[1];
      final trigger2 = stage2.triggers.first;

      expect(
        testDef.stages.first.injection?.placement,
        TestQuestionPlacement.page,
      );
      expect(stage2.injection?.placement, TestQuestionPlacement.review);
      expect(trigger2.strategy, equals('FirstBrownAfterBlueRunRule'));
      expect(trigger2.action, equals(TriggerAction.scheduleReview));
      expect(trigger2.nextStage, equals('completed'));
      expect(
        trigger2.reviewNotification?.titleKey,
        equals('Test Verification Required'),
      );
      expect(trigger2.reviewNotification?.delayMinutes, equals(5));
    });

    test('TestEngine filters injections by declared placement', () {
      final definitions = loadTestDefinitionsFromYaml(yamlString);
      final engine = DefaultTestEngine(
        testDefinitions: definitions,
        registry: TriggerRegistry(),
      );
      const eating = ActiveTestProtocol(
        id: 'eating',
        testId: 'blue_meal_transit',
        currentStageId: 'eat_meal',
      );
      const awaiting = ActiveTestProtocol(
        id: 'awaiting',
        testId: 'blue_meal_transit',
        currentStageId: 'awaiting_transit',
      );

      expect(
        engine.getInjectedQuestionIds(
          activeTest: eating,
          flowType: 'Meal Entry',
          placement: TestQuestionPlacement.page,
          pageIndex: 0,
        ),
        ['blue_meal_percentage', 'blue_meal_duration'],
      );
      expect(
        engine.getInjectedQuestionIds(
          activeTest: eating,
          flowType: 'Meal Entry',
          placement: TestQuestionPlacement.review,
        ),
        isEmpty,
      );
      expect(
        engine.getInjectedQuestionIds(
          activeTest: awaiting,
          flowType: 'Bowel Movements',
          placement: TestQuestionPlacement.review,
        ),
        ['bm_color'],
      );
      expect(
        engine.getInjectedQuestionIds(
          activeTest: awaiting,
          flowType: 'Bowel Movements',
          placement: TestQuestionPlacement.page,
          pageIndex: 0,
        ),
        isEmpty,
      );
    });

    test('TestEngine should evaluate custom TestTriggerStrategy from TriggerRegistry', () async {
      final definitions = loadTestDefinitionsFromYaml(yamlString);
      final registry = TriggerRegistry({
        'BlueMealEatenRule': BlueMealEatenRule(),
        'FirstBrownAfterBlueRunRule': FirstBrownAfterBlueRunRule(),
      });

      final engine = DefaultTestEngine(
        testDefinitions: definitions,
        registry: registry,
      );

      var activeTest = const ActiveTestProtocol(
        id: 'user_session_123',
        testId: 'blue_meal_transit',
        currentStageId: 'eat_meal',
      );

      // 1. Partial meal response -> should NOT trigger transition
      final partialMealEntry = Entry(
        subUserId: 'sub_1',
        stamp: DateTime.now(),
        entityType: 'event',
        data: {'type': 'Meal Entry', 'blue_meal_percentage': '50%'},
      );

      var result = await engine.processEntry(
        activeTest: activeTest,
        currentResponse: partialMealEntry,
      );
      expect(result.stageChanged, isFalse);

      // 2. Full meal response -> triggers transition to awaiting_transit
      final fullMealEntry = Entry(
        subUserId: 'sub_1',
        stamp: DateTime.now(),
        entityType: 'event',
        data: {'type': 'Meal Entry', 'blue_meal_percentage': '100%'},
      );

      result = await engine.processEntry(
        activeTest: activeTest,
        currentResponse: fullMealEntry,
      );
      expect(result.stageChanged, isTrue);
      expect(result.newStageId, equals('awaiting_transit'));

      activeTest = result.updatedTest;

      // 3. BM response matching FirstBrownAfterBlueRunRule with schedule_review action
      final bmEntry = Entry(
        subUserId: 'sub_1',
        stamp: DateTime.now(),
        entityType: 'event',
        data: {'type': 'Bowel Movements', 'bm_color': 'blue'},
      );

      result = await engine.processEntry(
        activeTest: activeTest,
        currentResponse: bmEntry,
      );

      expect(result.action, equals(TriggerAction.scheduleReview));
      expect(
        result.reviewNotification?.titleKey,
        equals('Test Verification Required'),
      );
    });

    test('TestEngine should allow manual stage advancement', () {
      final definitions = loadTestDefinitionsFromYaml(yamlString);
      final engine = DefaultTestEngine(
        testDefinitions: definitions,
        registry: TriggerRegistry(),
      );

      var activeTest = const ActiveTestProtocol(
        id: 'user_session_456',
        testId: 'blue_meal_transit',
        currentStageId: 'eat_meal',
      );

      // Manual advance without target stage -> defaults to next stage
      var result = engine.advanceStage(activeTest: activeTest);
      expect(result.stageChanged, isTrue);
      expect(result.newStageId, equals('awaiting_transit'));

      activeTest = result.updatedTest;

      // Manual advance directly to targetStageId 'completed'
      result = engine.advanceStage(
        activeTest: activeTest,
        targetStageId: 'completed',
      );
      expect(result.stageChanged, isTrue);
      expect(result.newStageId, equals('completed'));
      expect(result.updatedTest.isCompleted, isTrue);
    });
  });
}
