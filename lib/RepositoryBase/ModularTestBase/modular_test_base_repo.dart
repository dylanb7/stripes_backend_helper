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
  bool _disposed = false;
  bool _loading = false;
  bool _loadFailed = false;
  late Future<void> _ready;

  /// Completes when the current persisted-protocol load finishes.
  Future<void> get ready => _ready;

  ModularTestsRepo({
    required this.source,
    required this.engine,
    required this.definitions,
    List<ActiveTestProtocol>? initialProtocols,
  }) {
    if (initialProtocols != null) {
      _protocolsSubject.add(initialProtocols);
    }
    reload();
  }

  /// Reload persisted protocols, sharing any load already in progress.
  Future<void> reload() {
    if (_disposed) {
      return Future.error(StateError('Test repository is disposed'));
    }
    if (_loading) return ready;
    _loading = true;
    _loadFailed = false;
    _ready = _loadInProtocols();
    // Stream consumers receive failures even without awaiting readiness.
    // Keep the original future's error available to waiting mutations.
    _ready.ignore();
    return ready;
  }

  /// Wait for startup, retrying a previous failure without reloading successes.
  Future<void> ensureReady() {
    if (_disposed) {
      return Future.error(StateError('Test repository is disposed'));
    }
    return _loadFailed ? reload() : ready;
  }

  Future<void> _loadInProtocols() async {
    try {
      final loaded = await source.loadAllActiveProtocols();
      if (!_disposed) _protocolsSubject.add(loaded);
    } catch (error, stack) {
      _loadFailed = true;
      if (!_disposed) _protocolsSubject.addError(error, stack);
      rethrow;
    } finally {
      _loading = false;
    }
  }

  Future<void> _requireReady() async {
    if (_disposed) throw StateError('Test repository is disposed');
    await ready;
    if (_disposed) throw StateError('Test repository is disposed');
  }

  Stream<List<ActiveTestProtocol>> get activeProtocols =>
      _protocolsSubject.stream;

  List<ActiveTestProtocol> get currentProtocols =>
      _protocolsSubject.valueOrNull ?? [];

  Future<void> updateProtocol(ActiveTestProtocol protocol) async {
    await _requireReady();
    await source.updateActiveProtocol(protocol);
    if (_disposed) return;
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
    await _requireReady();
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
    await _requireReady();
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
    if (_disposed) return;
    _disposed = true;
    _protocolsSubject.close();
  }
}
