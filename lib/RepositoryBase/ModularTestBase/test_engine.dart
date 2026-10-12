import 'package:stripes_backend_helper/RepositoryBase/EntryBase/entry.dart';

import 'test_definition.dart';

class TestEvaluationResult {
  final ActiveTestProtocol updatedTest;
  final bool stageChanged;
  final String? previousStageId;
  final String? newStageId;
  final TriggerAction action;
  final NotificationConfig? reviewNotification;

  const TestEvaluationResult({
    required this.updatedTest,
    this.stageChanged = false,
    this.previousStageId,
    this.newStageId,
    this.action = TriggerAction.transition,
    this.reviewNotification,
  });
}

abstract class TestEngine {
  /// Evaluates an incoming entry against active test protocols.
  Future<TestEvaluationResult> processEntry({
    required ActiveTestProtocol activeTest,
    required Entry currentResponse,
    List<Entry> historicalResponses = const [],
  });

  /// Manually advances the active test to a target stage (or next sequential stage).
  TestEvaluationResult advanceStage({
    required ActiveTestProtocol activeTest,
    String? targetStageId,
  });

  /// Evaluates question IDs to inject for a specific record path / flow type
  List<String> getInjectedQuestionIds({
    required ActiveTestProtocol activeTest,
    required String flowType,
    TestQuestionPlacement placement = TestQuestionPlacement.page,
    int pageIndex = 0,
  });
}

class DefaultTestEngine extends TestEngine {
  final Map<String, TestDefinition> definitions;
  final TriggerRegistry registry;

  DefaultTestEngine({
    required List<TestDefinition> testDefinitions,
    required this.registry,
  }) : definitions = {for (final d in testDefinitions) d.id: d};

  @override
  Future<TestEvaluationResult> processEntry({
    required ActiveTestProtocol activeTest,
    required Entry currentResponse,
    List<Entry> historicalResponses = const [],
  }) async {
    final definition = definitions[activeTest.testId];
    if (definition == null || activeTest.isCompleted) {
      return TestEvaluationResult(updatedTest: activeTest);
    }

    final currentStage = definition.stages.firstWhere(
      (s) => s.id == activeTest.currentStageId,
      orElse: () => definition.stages.first,
    );

    if (currentStage.isTerminal) {
      final updated = activeTest.copyWith(isCompleted: true);
      return TestEvaluationResult(updatedTest: updated);
    }

    final eventType = currentResponse.subtype ?? currentResponse.entityType;
    if (definition.listensTo.isNotEmpty &&
        !definition.listensTo.contains(eventType)) {
      return TestEvaluationResult(updatedTest: activeTest);
    }

    for (final trigger in currentStage.triggers) {
      final strategy = registry.get(trigger.strategy);
      if (strategy == null) continue;

      final shouldTrigger = await strategy.shouldTrigger(
        currentResponse: currentResponse,
        historicalResponses: historicalResponses,
        testState: activeTest,
      );

      if (shouldTrigger) {
        final nextStageId = trigger.nextStage;
        final nextStageObj = definition.stages.firstWhere(
          (s) => s.id == nextStageId,
          orElse: () => TestStage(id: nextStageId, triggers: const []),
        );

        final updatedContext = Map<String, dynamic>.from(activeTest.testContext)
          ..['last_event_type'] = eventType
          ..['last_updated'] = DateTime.now().toUtc().toIso8601String();

        final updatedTest = activeTest.copyWith(
          currentStageId: trigger.action == TriggerAction.transition
              ? nextStageId
              : activeTest.currentStageId,
          isCompleted:
              trigger.action == TriggerAction.transition &&
              nextStageObj.isTerminal,
          testContext: updatedContext,
        );

        return TestEvaluationResult(
          updatedTest: updatedTest,
          stageChanged: trigger.action == TriggerAction.transition,
          previousStageId: currentStage.id,
          newStageId: nextStageId,
          action: trigger.action,
          reviewNotification: trigger.reviewNotification,
        );
      }
    }

    return TestEvaluationResult(updatedTest: activeTest);
  }

  @override
  TestEvaluationResult advanceStage({
    required ActiveTestProtocol activeTest,
    String? targetStageId,
  }) {
    final definition = definitions[activeTest.testId];
    if (definition == null || activeTest.isCompleted) {
      return TestEvaluationResult(updatedTest: activeTest);
    }

    final currentIndex = definition.stages.indexWhere(
      (s) => s.id == activeTest.currentStageId,
    );

    String? nextStageId = targetStageId;
    if (nextStageId == null || nextStageId.isEmpty) {
      final currentStage = currentIndex != -1
          ? definition.stages[currentIndex]
          : null;
      if (currentStage != null && currentStage.triggers.isNotEmpty) {
        nextStageId = currentStage.triggers.first.nextStage;
      } else if (currentIndex != -1 &&
          currentIndex + 1 < definition.stages.length) {
        nextStageId = definition.stages[currentIndex + 1].id;
      }
    }

    if (nextStageId == null || nextStageId == activeTest.currentStageId) {
      return TestEvaluationResult(updatedTest: activeTest);
    }

    final nextStageObj = definition.stages.firstWhere(
      (s) => s.id == nextStageId,
      orElse: () => TestStage(id: nextStageId!, triggers: const []),
    );

    final updatedContext = Map<String, dynamic>.from(activeTest.testContext)
      ..['manually_advanced'] = true
      ..['last_updated'] = DateTime.now().toUtc().toIso8601String();

    final updatedTest = activeTest.copyWith(
      currentStageId: nextStageId,
      isCompleted: nextStageObj.isTerminal,
      testContext: updatedContext,
    );

    return TestEvaluationResult(
      updatedTest: updatedTest,
      stageChanged: true,
      previousStageId: activeTest.currentStageId,
      newStageId: nextStageId,
      action: TriggerAction.transition,
    );
  }

  @override
  List<String> getInjectedQuestionIds({
    required ActiveTestProtocol activeTest,
    required String flowType,
    TestQuestionPlacement placement = TestQuestionPlacement.page,
    int pageIndex = 0,
  }) {
    final definition = definitions[activeTest.testId];
    if (definition == null || activeTest.isCompleted) {
      return const [];
    }

    final currentStage = definition.stages.firstWhere(
      (s) => s.id == activeTest.currentStageId,
      orElse: () => definition.stages.first,
    );

    final injection = currentStage.injection;
    if (injection != null &&
        (injection.targetRecordPath == flowType ||
            injection.targetRecordPath.isEmpty) &&
        injection.placement == placement &&
        (placement == TestQuestionPlacement.review ||
            injection.pageIndex == pageIndex)) {
      return injection.questionIds;
    }

    return const [];
  }
}
