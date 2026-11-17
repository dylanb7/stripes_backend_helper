import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_backend_helper/RepositoryBase/EntryBase/entry.dart';
import 'package:stripes_backend_helper/RepositoryBase/ModularTestBase/modular_test_base_repo.dart';
import 'package:stripes_backend_helper/RepositoryBase/ModularTestBase/test_definition.dart';
import 'package:stripes_backend_helper/RepositoryBase/ModularTestBase/test_engine.dart';

const _initial = ActiveTestProtocol(
  id: 'protocol',
  testId: 'test',
  currentStageId: 'initial',
);
const _persisted = ActiveTestProtocol(
  id: 'protocol',
  testId: 'test',
  currentStageId: 'persisted',
);

class _Source implements ActiveTestProtocolSource {
  var load = Completer<List<ActiveTestProtocol>>();
  int loadCalls = 0;
  final saved = <ActiveTestProtocol>[];
  Completer<void>? write;

  @override
  Future<List<ActiveTestProtocol>> loadAllActiveProtocols() {
    loadCalls++;
    return load.future;
  }

  @override
  Future<void> updateActiveProtocol(ActiveTestProtocol protocol) async {
    saved.add(protocol);
    await write?.future;
  }
}

class _Engine extends TestEngine {
  final evaluated = <ActiveTestProtocol>[];

  TestEvaluationResult _advance(ActiveTestProtocol protocol) {
    evaluated.add(protocol);
    return TestEvaluationResult(
      updatedTest: protocol.copyWith(
        currentStageId: '${protocol.currentStageId}:next',
      ),
      stageChanged: true,
    );
  }

  @override
  Future<TestEvaluationResult> processEntry({
    required ActiveTestProtocol activeTest,
    required Entry currentResponse,
    List<Entry> historicalResponses = const [],
  }) async => _advance(activeTest);

  @override
  TestEvaluationResult advanceStage({
    required ActiveTestProtocol activeTest,
    String? targetStageId,
  }) => _advance(activeTest);

  @override
  List<String> getInjectedQuestionIds({
    required ActiveTestProtocol activeTest,
    required String flowType,
    TestQuestionPlacement placement = TestQuestionPlacement.page,
    int pageIndex = 0,
  }) => const [];
}

Entry _entry() => Entry(
  subUserId: 'profile',
  stamp: DateTime.utc(2026),
  entityType: 'event',
  data: const {'type': 'category.BM'},
);

void main() {
  test(
    'explicit in-memory initial protocols remain immediately readable',
    () async {
      final source = _Source();
      final repo = ModularTestsRepo(
        source: source,
        engine: _Engine(),
        definitions: const [],
        initialProtocols: const [_initial],
      );
      addTearDown(repo.dispose);
      expect(repo.currentProtocols, [_initial]);
      source.load.complete([_persisted]);
      await repo.ready;
      expect(repo.currentProtocols, [_persisted]);
    },
  );

  test(
    'updates wait for initial load and preserve other loaded protocols',
    () async {
      final source = _Source();
      final repo = ModularTestsRepo(
        source: source,
        engine: _Engine(),
        definitions: const [],
      );
      addTearDown(repo.dispose);
      final events = <List<ActiveTestProtocol>>[];
      final subscription = repo.activeProtocols.listen(events.add);
      addTearDown(subscription.cancel);

      final operation = repo.updateProtocol(_initial);
      await Future<void>.delayed(Duration.zero);
      expect(source.saved, isEmpty);
      expect(events, isEmpty);

      final other = _persisted.copyWith(id: 'other');
      source.load.complete([other]);
      await operation;
      expect(source.saved, [_initial]);
      expect(repo.currentProtocols, [other, _initial]);
    },
  );

  for (final process in [false, true]) {
    test(
      '${process ? 'entry processing' : 'manual advance'} waits for persisted stage',
      () async {
        final source = _Source();
        final engine = _Engine();
        final repo = ModularTestsRepo(
          source: source,
          engine: engine,
          definitions: const [],
          initialProtocols: const [_initial],
        );
        addTearDown(repo.dispose);
        final Future<Object?> operation = process
            ? repo.processEntry(_entry())
            : repo.advanceStage(activeTestId: 'protocol');
        await Future<void>.delayed(Duration.zero);
        expect(engine.evaluated, isEmpty);
        expect(source.saved, isEmpty);

        source.load.complete([_persisted]);
        await operation;
        expect(engine.evaluated, [_persisted]);
        expect(source.saved.single.currentStageId, 'persisted:next');
      },
    );
  }

  test(
    'load failures reach the stream and prevent every mutation path',
    () async {
      final source = _Source();
      final engine = _Engine();
      final repo = ModularTestsRepo(
        source: source,
        engine: engine,
        definitions: const [],
      );
      addTearDown(repo.dispose);
      final error = StateError('Unable to read persisted protocols');
      final streamFailure = expectLater(
        repo.activeProtocols.first,
        throwsA(same(error)),
      );
      final readyFailure = expectLater(repo.ready, throwsA(same(error)));
      source.load.completeError(error);
      await Future.wait([streamFailure, readyFailure]);

      await expectLater(repo.updateProtocol(_initial), throwsA(same(error)));
      await expectLater(
        repo.advanceStage(activeTestId: 'protocol'),
        throwsA(same(error)),
      );
      await expectLater(repo.processEntry(_entry()), throwsA(same(error)));
      expect(source.saved, isEmpty);
      expect(engine.evaluated, isEmpty);
    },
  );

  test(
    'a failed startup can retry, sharing readiness with waiting mutations',
    () async {
      final source = _Source();
      final repo = ModularTestsRepo(
        source: source,
        engine: _Engine(),
        definitions: const [],
      );
      addTearDown(repo.dispose);
      final errors = <Object>[];
      final events = <List<ActiveTestProtocol>>[];
      final subscription = repo.activeProtocols.listen(
        events.add,
        onError: errors.add,
      );
      addTearDown(subscription.cancel);
      final error = StateError('offline');
      final failed = expectLater(repo.ready, throwsA(same(error)));
      source.load.completeError(error);
      await failed;

      source.load = Completer<List<ActiveTestProtocol>>();
      final retry = repo.ensureReady();
      expect(repo.ensureReady(), same(retry));
      expect(repo.reload(), same(retry));
      expect(repo.ready, same(retry));
      expect(source.loadCalls, 2);
      final update = repo.updateProtocol(
        _persisted.copyWith(currentStageId: 'updated'),
      );
      await Future<void>.delayed(Duration.zero);
      expect(source.saved, isEmpty);
      expect(events, isEmpty);

      final other = _persisted.copyWith(id: 'other');
      source.load.complete([_persisted, other]);
      await Future.wait([retry, update]);
      expect(repo.currentProtocols.map((p) => p.currentStageId), [
        'updated',
        'persisted',
      ]);
      expect(errors, [error]);
      expect(source.saved.single.currentStageId, 'updated');
      await repo.ensureReady();
      expect(source.loadCalls, 2);
      expect(await repo.activeProtocols.first, repo.currentProtocols);
    },
  );

  test(
    'explicit reload replaces successful readiness and coalesces callers',
    () async {
      final source = _Source();
      final repo = ModularTestsRepo(
        source: source,
        engine: _Engine(),
        definitions: const [],
      );
      addTearDown(repo.dispose);
      source.load.complete([_initial]);
      final initialReady = repo.ready;
      await initialReady;
      source.load = Completer<List<ActiveTestProtocol>>();
      final reload = repo.reload();
      expect(reload, isNot(same(initialReady)));
      expect(repo.reload(), same(reload));
      expect(repo.ensureReady(), same(reload));
      source.load.complete([_persisted]);
      await reload;
      expect(repo.currentProtocols, [_persisted]);
      expect(source.loadCalls, 2);
    },
  );

  test(
    'disposing during load closes the stream and refuses waiting writes',
    () async {
      final source = _Source();
      final repo = ModularTestsRepo(
        source: source,
        engine: _Engine(),
        definitions: const [],
      );
      final events = <List<ActiveTestProtocol>>[];
      final closed = Completer<void>();
      repo.activeProtocols.listen(events.add, onDone: closed.complete);
      final operation = expectLater(
        repo.updateProtocol(_initial),
        throwsStateError,
      );
      repo.dispose();
      repo.dispose();
      source.load.complete([_persisted]);
      await Future.wait([repo.ready, operation, closed.future]);
      expect(events, isEmpty);
      expect(source.saved, isEmpty);
    },
  );

  test('a failed load after disposal is handled without publishing to the closed stream', () async {
    final source = _Source();
    final repo = ModularTestsRepo(
      source: source,
      engine: _Engine(),
      definitions: const [],
    );
    repo.dispose();
    source.load.completeError(StateError('offline'));
    // Let the fire-and-forget startup settle before explicitly awaiting it.
    await Future<void>.delayed(Duration.zero);
    await expectLater(repo.ready, throwsStateError);
    expect(source.saved, isEmpty);
  });

  test(
    'disposing during an accepted write does not publish after stream closure',
    () async {
      final source = _Source()..write = Completer<void>();
      final repo = ModularTestsRepo(
        source: source,
        engine: _Engine(),
        definitions: const [],
      );
      source.load.complete([_persisted]);
      await repo.ready;
      final updated = _persisted.copyWith(currentStageId: 'updated');
      final operation = repo.updateProtocol(updated);
      await Future<void>.delayed(Duration.zero);
      expect(source.saved, [updated]);
      repo.dispose();
      source.write!.complete();
      await operation;
      expect(repo.currentProtocols, [_persisted]);
    },
  );
}
