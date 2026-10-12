import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:yaml/yaml.dart';
import 'package:stripes_backend_helper/RepositoryBase/EntryBase/entry.dart';

@immutable
class ActiveTestProtocol with EquatableMixin {
  final String id;
  final String testId;
  final String currentStageId;
  final Map<String, dynamic> testContext;
  final bool isCompleted;

  const ActiveTestProtocol({
    required this.id,
    required this.testId,
    required this.currentStageId,
    this.testContext = const {},
    this.isCompleted = false,
  });

  ActiveTestProtocol copyWith({
    String? id,
    String? testId,
    String? currentStageId,
    Map<String, dynamic>? testContext,
    bool? isCompleted,
  }) {
    return ActiveTestProtocol(
      id: id ?? this.id,
      testId: testId ?? this.testId,
      currentStageId: currentStageId ?? this.currentStageId,
      testContext: testContext ?? this.testContext,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'testId': testId,
      'currentStageId': currentStageId,
      'testContext': testContext,
      'isCompleted': isCompleted,
    };
  }

  factory ActiveTestProtocol.fromJson(Map<String, dynamic> json) {
    return ActiveTestProtocol(
      id: json['id'] as String,
      testId: json['testId'] as String,
      currentStageId: json['currentStageId'] as String,
      testContext: json['testContext'] != null
          ? Map<String, dynamic>.from(json['testContext'] as Map)
          : const {},
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
    id,
    testId,
    currentStageId,
    testContext,
    isCompleted,
  ];
}

@immutable
class TestDefinition with EquatableMixin {
  final String id;
  final String nameKey;
  final Set<String> listensTo;
  final List<TestStage> stages;

  const TestDefinition({
    required this.id,
    required this.nameKey,
    required this.listensTo,
    required this.stages,
  });

  factory TestDefinition.fromYaml(YamlMap yaml) {
    final stagesYaml = yaml['stages'] as YamlList;
    final listensRaw = yaml['listensTo'];
    Set<String> listensSet = {};
    if (listensRaw is YamlList) {
      listensSet = listensRaw.map((e) => e.toString()).toSet();
    } else if (listensRaw is Iterable) {
      listensSet = listensRaw.map((e) => e.toString()).toSet();
    }

    return TestDefinition(
      id: yaml['id'] as String,
      nameKey: (yaml['name'] ?? yaml['nameKey'] ?? '') as String,
      listensTo: listensSet,
      stages: stagesYaml.map((s) => TestStage.fromYaml(s as YamlMap)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nameKey': nameKey,
      'listensTo': listensTo.toList(),
      'stages': stages.map((s) => s.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [id, nameKey, listensTo, stages];
}

@immutable
class TestStage with EquatableMixin {
  final String id;
  final bool isTerminal;
  final List<String> stageQuestionIds;
  final StageInjection? injection;
  final List<StageTrigger> triggers;

  const TestStage({
    required this.id,
    this.isTerminal = false,
    this.stageQuestionIds = const [],
    this.injection,
    required this.triggers,
  });

  factory TestStage.fromYaml(YamlMap yaml) {
    final qIdsRaw = yaml['questionIds'] ?? yaml['stageQuestionIds'];
    List<String> qIds = [];
    if (qIdsRaw is YamlList) {
      qIds = qIdsRaw.map((e) => e.toString()).toList();
    } else if (qIdsRaw is Iterable) {
      qIds = qIdsRaw.map((e) => e.toString()).toList();
    }

    return TestStage(
      id: yaml['id'] as String,
      isTerminal: yaml['isTerminal'] == true,
      stageQuestionIds: qIds,
      injection: yaml['injections'] != null
          ? StageInjection.fromYaml(yaml['injections'] as YamlMap)
          : null,
      triggers: (yaml['triggers'] as YamlList? ?? [])
          .map((t) => StageTrigger.fromYaml(t as YamlMap))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'isTerminal': isTerminal,
      'stageQuestionIds': stageQuestionIds,
      'injection': injection?.toJson(),
      'triggers': triggers.map((t) => t.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    isTerminal,
    stageQuestionIds,
    injection,
    triggers,
  ];
}

@immutable
class StageInjection with EquatableMixin {
  final String targetRecordPath;
  final TestQuestionPlacement placement;
  final int pageIndex;
  final List<String> questionIds;

  const StageInjection({
    required this.targetRecordPath,
    this.placement = TestQuestionPlacement.page,
    required this.pageIndex,
    required this.questionIds,
  });

  factory StageInjection.fromYaml(YamlMap yaml) {
    final qIdsRaw = yaml['questionIds'];
    List<String> qIds = [];
    if (qIdsRaw is YamlList) {
      qIds = qIdsRaw.map((e) => e.toString()).toList();
    } else if (qIdsRaw is Iterable) {
      qIds = qIdsRaw.map((e) => e.toString()).toList();
    }

    return StageInjection(
      targetRecordPath:
          (yaml['recordPath'] ?? yaml['targetRecordPath'] ?? '') as String,
      placement: TestQuestionPlacement.parse(yaml['placement']),
      pageIndex: yaml['pageIndex'] as int? ?? 0,
      questionIds: qIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'targetRecordPath': targetRecordPath,
      'placement': placement.name,
      'pageIndex': pageIndex,
      'questionIds': questionIds,
    };
  }

  @override
  List<Object?> get props => [
    targetRecordPath,
    placement,
    pageIndex,
    questionIds,
  ];
}

enum TestQuestionPlacement {
  page,
  review;

  static TestQuestionPlacement parse(dynamic value) {
    if (value == null) return TestQuestionPlacement.page;
    return TestQuestionPlacement.values.firstWhere(
      (placement) => placement.name == value.toString(),
      orElse: () => throw FormatException(
        'Unknown test question placement: $value. Expected page or review.',
      ),
    );
  }
}

abstract class TestTriggerStrategy {
  /// Evaluates whether the active test should advance to its next stage.
  ///
  /// [currentResponse]: The stamp/record just submitted by the user.
  /// [historicalResponses]: Prior user logs for calculating sequences or trends.
  Future<bool> shouldTrigger({
    required Entry currentResponse,
    required List<Entry> historicalResponses,
    required ActiveTestProtocol testState,
  });
}

class TriggerRegistry {
  final Map<String, TestTriggerStrategy> _strategies;

  TriggerRegistry([Map<String, TestTriggerStrategy>? initial])
    : _strategies = Map.of(initial ?? {});

  void register(String name, TestTriggerStrategy strategy) {
    _strategies[name] = strategy;
  }

  TestTriggerStrategy? get(String strategyName) => _strategies[strategyName];
}

enum TriggerAction { transition, scheduleReview }

@immutable
class StageTrigger with EquatableMixin {
  final String strategy;
  final TriggerAction action;
  final String nextStage;
  final NotificationConfig? reviewNotification;

  const StageTrigger({
    required this.strategy,
    this.action = TriggerAction.transition,
    required this.nextStage,
    this.reviewNotification,
  });

  factory StageTrigger.fromYaml(YamlMap yaml) {
    final actionStr = yaml['action'] as String? ?? 'transition';
    return StageTrigger(
      strategy: yaml['strategy'] as String,
      action: actionStr == 'schedule_review' || actionStr == 'scheduleReview'
          ? TriggerAction.scheduleReview
          : TriggerAction.transition,
      nextStage: yaml['nextStage'] as String,
      reviewNotification: yaml['reviewNotification'] != null
          ? NotificationConfig.fromYaml(yaml['reviewNotification'] as YamlMap)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'strategy': strategy,
      'action': action.name,
      'nextStage': nextStage,
      'reviewNotification': reviewNotification?.toJson(),
    };
  }

  @override
  List<Object?> get props => [strategy, action, nextStage, reviewNotification];
}

@immutable
class NotificationConfig with EquatableMixin {
  final String titleKey;
  final String bodyKey;
  final int delayMinutes;

  const NotificationConfig({
    required this.titleKey,
    required this.bodyKey,
    this.delayMinutes = 0,
  });

  factory NotificationConfig.fromYaml(YamlMap yaml) {
    return NotificationConfig(
      titleKey: yaml['titleKey'] as String,
      bodyKey: yaml['bodyKey'] as String,
      delayMinutes: yaml['delayMinutes'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'titleKey': titleKey,
      'bodyKey': bodyKey,
      'delayMinutes': delayMinutes,
    };
  }

  @override
  List<Object?> get props => [titleKey, bodyKey, delayMinutes];
}
