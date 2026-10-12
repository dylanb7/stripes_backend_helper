import 'package:rxdart/rxdart.dart';
import 'package:stripes_backend_helper/RepositoryBase/EntryBase/entry.dart';

import 'test_definition.dart';
import 'test_engine.dart';

abstract class ActiveTestProtocolSource {
  Future<List<ActiveTestProtocol>> loadAllActiveProtocols();
  Future<void> updateActiveProtocol(ActiveTestProtocol protocol);
}

class ModularTestsRepo {
  final ActiveTestProtocolSource source;
  final TestEngine engine;
  final List<TestDefinition> definitions;

  final BehaviorSubject<List<ActiveTestProtocol>> _protocolsSubject =
      BehaviorSubject();

  ModularTestsRepo({
    required this.source,
    required this.engine,
    required this.definitions,
    List<ActiveTestProtocol>? initialProtocols,
  }) {
    if (initialProtocols != null) {
      _protocolsSubject.add(initialProtocols);
    }
    _loadInProtocols();
  }

  Future<void> _loadInProtocols() async {
    final loaded = await source.loadAllActiveProtocols();
    _protocolsSubject.add(loaded);
  }

  Stream<List<ActiveTestProtocol>> get activeProtocols =>
      _protocolsSubject.stream;

  List<ActiveTestProtocol> get currentProtocols =>
      _protocolsSubject.valueOrNull ?? [];

  Future<void> updateProtocol(ActiveTestProtocol protocol) async {
    await source.updateActiveProtocol(protocol);
    final current = currentProtocols.toList();
    final index = current.indexWhere((p) => p.id == protocol.id);
    if (index != -1) {
      current[index] = protocol;
    } else {
      current.add(protocol);
    }
    _protocolsSubject.add(current);
  }

  Future<List<TestEvaluationResult>> processEntry(
    Entry entry, {
    List<Entry> historicalResponses = const [],
  }) async {
    final results = <TestEvaluationResult>[];
    final activeList = currentProtocols.where((p) => !p.isCompleted).toList();

    for (final activeTest in activeList) {
      final res = await engine.processEntry(
        activeTest: activeTest,
        currentResponse: entry,
        historicalResponses: historicalResponses,
      );
      if (res.stageChanged) {
        await updateProtocol(res.updatedTest);
      }
      results.add(res);
    }
    return results;
  }

  Future<TestEvaluationResult?> advanceStage({
    required String activeTestId,
    String? targetStageId,
  }) async {
    final activeList = currentProtocols.toList();
    final index = activeList.indexWhere((p) => p.id == activeTestId);
    if (index == -1) return null;

    final activeTest = activeList[index];
    final res = engine.advanceStage(
      activeTest: activeTest,
      targetStageId: targetStageId,
    );

    if (res.stageChanged) {
      await updateProtocol(res.updatedTest);
    }
    return res;
  }

  List<String> getInjectedQuestionIds(
    String flowType, {
    TestQuestionPlacement placement = TestQuestionPlacement.page,
    int pageIndex = 0,
  }) {
    final questionIds = <String>[];
    final activeList = currentProtocols.where((p) => !p.isCompleted);

    for (final activeTest in activeList) {
      final injected = engine.getInjectedQuestionIds(
        activeTest: activeTest,
        flowType: flowType,
        placement: placement,
        pageIndex: pageIndex,
      );
      questionIds.addAll(injected);
    }
    return questionIds;
  }

  void dispose() {
    _protocolsSubject.close();
  }
}
