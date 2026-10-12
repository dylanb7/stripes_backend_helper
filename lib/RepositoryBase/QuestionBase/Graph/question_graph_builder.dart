import 'package:flutter/foundation.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/Graph/display_config.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/Graph/question_edge.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/Graph/question_graph.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/Graph/question_node.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_repo_base.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/transform.dart';


class QuestionGraphBuilder {
  QuestionGraphBuilder._();

  static QuestionGraph build({
    required QuestionHome home,
    required List<RecordPath> recordPaths,
    bool autoCategorize = false,
    Map<String, DisplayConfig>? displayConfigs,
    Map<String, EntryConfig>? entryConfigs,
  }) {
    final nodes = <String, QuestionNode>{};
    final dependents = <String, Set<String>>{};
    final globalState = <String, ValueNotifier<QuestionNodeState>>{};

    _buildQuestionNodes(
      home: home,
      nodes: nodes,
      dependents: dependents,
      globalState: globalState,
      displayConfigs: displayConfigs,
      entryConfigs: entryConfigs,
    );

    final effectiveRecordPaths = autoCategorize
        ? _applyAutoCategorization(home: home, recordPaths: recordPaths)
        : List<RecordPath>.from(recordPaths);

    final pagesByPath = <String, List<PageLayout>>{};
    final recordPathsByName = <String, RecordPath>{};

    _buildPathLayouts(
      recordPaths: effectiveRecordPaths,
      pagesByPath: pagesByPath,
      recordPathsByName: recordPathsByName,
      dependents: dependents,
    );

    return QuestionGraph.internal(
      nodes: nodes,
      pagesByPath: pagesByPath,
      recordPathsByName: recordPathsByName,
      dependents: dependents,
      globalState: globalState,
    );
  }

  static void _buildQuestionNodes({
    required QuestionHome home,
    required Map<String, QuestionNode> nodes,
    required Map<String, Set<String>> dependents,
    required Map<String, ValueNotifier<QuestionNodeState>> globalState,
    Map<String, DisplayConfig>? displayConfigs,
    Map<String, EntryConfig>? entryConfigs,
  }) {
    for (final entry in home.all.entries) {
      final q = entry.value;
      final edges = <QuestionEdge>[];

      if (q.dependsOn != null) {
        for (final group in q.dependsOn!.groups) {
          for (final sourceId in _extractQuestionIds(group)) {
            edges.add(QuestionEdge(
              fromId: sourceId,
              toId: q.id,
              kind: EdgeKind.dependsOn,
            ));
            dependents.putIfAbsent(sourceId, () => <String>{}).add(q.id);
          }
        }
      }

      if (q.requirement != null) {
        for (final group in q.requirement!.groups) {
          for (final sourceId in _extractQuestionIds(group)) {
            if (sourceId != q.id) {
              edges.add(QuestionEdge(
                fromId: sourceId,
                toId: q.id,
                kind: EdgeKind.requires,
              ));
              dependents.putIfAbsent(sourceId, () => <String>{}).add(q.id);
            }
          }
        }
      }

      if (q.transform != null) {
        final xform = Transform.parse(q.transform);
        if (xform?.sourceId != null) {
          edges.add(QuestionEdge(
            fromId: xform!.sourceId!,
            toId: q.id,
            kind: EdgeKind.transformSource,
          ));
          dependents.putIfAbsent(xform.sourceId!, () => <String>{}).add(q.id);
        }
      }

      if (q.baselineContext != null) {
        for (final ctxId in q.baselineContext!) {
          edges.add(QuestionEdge(
            fromId: ctxId,
            toId: q.id,
            kind: EdgeKind.baselineContext,
          ));
        }
      }

      final displayConfig = displayConfigs?[q.id] ?? displayConfigs?[q.type];
      final entryConfig = entryConfigs?[q.id] ?? entryConfigs?[q.type];

      nodes[q.id] = QuestionNode(
        question: q,
        edges: edges,
        displayConfig: displayConfig,
        entryConfig: entryConfig,
      );

      globalState[q.id] = ValueNotifier(QuestionNodeState(
        enabled: q.enabled,
      ));
    }
  }

  static List<RecordPath> _applyAutoCategorization({
    required QuestionHome home,
    required List<RecordPath> recordPaths,
  }) {
    final effectiveRecordPaths = List<RecordPath>.from(recordPaths);
    final assignedQuestionIds = <String>{};

    for (final rp in effectiveRecordPaths) {
      for (final page in rp.pages) {
        assignedQuestionIds.addAll(page.questionIds);
      }
    }

    final unassignedByType = <String, List<Question>>{};
    for (final q in home.all.values) {
      if (!assignedQuestionIds.contains(q.id)) {
        unassignedByType.putIfAbsent(q.type, () => []).add(q);
      }
    }

    for (final entry in unassignedByType.entries) {
      final typeName = entry.key;
      final unassignedQList = entry.value;
      final unassignedQIds = unassignedQList.map((q) => q.id).toList();

      final existingIdx =
          effectiveRecordPaths.indexWhere((rp) => rp.name == typeName);
      if (existingIdx != -1) {
        final existing = effectiveRecordPaths[existingIdx];
        final updatedPages = List<PageLayout>.from(existing.pages)
          ..add(PageLayout(questionIds: unassignedQIds));
        effectiveRecordPaths[existingIdx] =
            existing.copyWith(pages: updatedPages);
      } else {
        final isBaselinePath = unassignedQList.any((q) => q.isBaseline);
        final autoPath = RecordPath(
          name: typeName,
          isBaseline: isBaselinePath,
          pages: [PageLayout(questionIds: unassignedQIds)],
        );
        effectiveRecordPaths.add(autoPath);
      }
    }

    return effectiveRecordPaths;
  }

  static void _buildPathLayouts({
    required List<RecordPath> recordPaths,
    required Map<String, List<PageLayout>> pagesByPath,
    required Map<String, RecordPath> recordPathsByName,
    required Map<String, Set<String>> dependents,
  }) {
    for (final rp in recordPaths) {
      recordPathsByName[rp.name] = rp;
      final pathPages = <PageLayout>[];
      for (final layout in rp.pages) {
        for (final group in layout.dependsOn.groups) {
          for (final sourceId in _extractQuestionIds(group)) {
            for (final qid in layout.questionIds) {
              dependents.putIfAbsent(sourceId, () => <String>{}).add(qid);
            }
          }
        }

        for (final group in layout.requirement.groups) {
          for (final sourceId in _extractQuestionIds(group)) {
            for (final qid in layout.questionIds) {
              dependents.putIfAbsent(sourceId, () => <String>{}).add(qid);
            }
          }
        }

        pathPages.add(layout);
      }
      pagesByPath[rp.name] = pathPages;
    }
  }

  static Set<String> _extractQuestionIds(Condition condition) {
    final ids = <String>{};
    if (condition is ConditionGroup) {
      for (final c in condition.conditions) {
        ids.addAll(_extractQuestionIds(c));
      }
    } else if (condition.questionId != null) {
      ids.add(condition.questionId!);
    }
    return ids;
  }
}
