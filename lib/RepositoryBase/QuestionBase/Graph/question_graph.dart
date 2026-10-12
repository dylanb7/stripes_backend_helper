import 'package:flutter/material.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/Graph/display_config.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/Graph/question_node.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/Graph/session_graph.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_repo_base.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/session_data.dart';
import 'package:stripes_backend_helper/RepositoryBase/StampBase/stamp.dart';

class QuestionGraph {
  final Map<String, QuestionNode> _nodes;

  final Map<String, List<PageLayout>> _pagesByPath;

  final Map<String, RecordPath> _recordPathsByName;

  final Map<String, Set<String>> _dependents;

  final Map<String, ValueNotifier<QuestionNodeState>> _globalState;

  @protected
  QuestionGraph.internal({
    required Map<String, QuestionNode> nodes,
    required Map<String, List<PageLayout>> pagesByPath,
    required Map<String, RecordPath> recordPathsByName,
    required Map<String, Set<String>> dependents,
    required Map<String, ValueNotifier<QuestionNodeState>> globalState,
  }) : _nodes = nodes,
       _pagesByPath = pagesByPath,
       _recordPathsByName = recordPathsByName,
       _dependents = dependents,
       _globalState = globalState;

  QuestionNode? node(String id) => _nodes[id];

  Iterable<QuestionNode> get nodes => _nodes.values;

  List<PageLayout> get pages =>
      List.unmodifiable(_pagesByPath.values.expand((p) => p));

  List<RecordPath> get recordPaths =>
      List.unmodifiable(_recordPathsByName.values);

  RecordPath? recordPath(String name) => _recordPathsByName[name];

  List<RecordPath> allRecordPaths({
    bool filterEnabled = true,
    PathProviderType type = PathProviderType.both,
  }) {
    return _recordPathsByName.values.where((layout) {
      if (filterEnabled && !layout.enabled) return false;
      if (type == PathProviderType.review && layout.period == null) {
        return false;
      }
      if (type == PathProviderType.record && layout.period != null) {
        return false;
      }
      return true;
    }).toList();
  }

  Map<String, List<Question>> questionsByType() {
    final byCategory = <String, List<Question>>{};

    for (final node in _nodes.values) {
      final q = node.question;
      byCategory.putIfAbsent(q.type, () => []).add(q);
    }

    for (final pathName in _recordPathsByName.keys) {
      if (!byCategory.containsKey(pathName)) {
        byCategory[pathName] = [];
      }
    }

    return byCategory;
  }

  Set<String> requiredBaselinesForPath(RecordPath path) {
    final baselines = <String>{};
    if (path.fromBaseline != null) baselines.add(path.fromBaseline!);
    for (final page in path.pages) {
      for (final qid in page.questionIds) {
        final q = _nodes[qid]?.question;
        if (q?.fromBaseline != null) {
          baselines.add(q!.fromBaseline!);
        }
      }
    }
    return baselines;
  }

  String? requiredBaselineForPath(RecordPath path) {
    final reqs = requiredBaselinesForPath(path);
    return reqs.isEmpty ? null : reqs.first;
  }

  PagesData? pagesDataForPath(
    String? pathName, {
    bool filterEnabled = false,
    List<Stamp>? baselines,
  }) {
    if (pathName == null) return null;
    final matching = _recordPathsByName[pathName];
    if (matching == null) return null;

    final loadedLayouts = <LoadedPageLayout>[];
    for (final layout in matching.pages) {
      final questions = <Question>[];
      for (final qid in layout.questionIds) {
        final q = _nodes[qid]?.question;
        if (q == null || (filterEnabled && !q.enabled)) {
          continue;
        }
        if (q.fromBaseline != null && baselines != null) {
          final bool hasBaseline = baselines.any(
            (element) => element.type == q.fromBaseline,
          );
          if (!hasBaseline) continue;
        }
        questions.add(q);
      }
      if (questions.isEmpty) continue;
      loadedLayouts.add(
        LoadedPageLayout(
          requirement: layout.requirement,
          questions: questions,
          dependsOn: layout.dependsOn,
          header: layout.header,
        ),
      );
    }
    return PagesData(path: matching, loadedLayouts: loadedLayouts);
  }

  List<RecordItem> availableRecordPaths(
    List<Stamp> baselines, {
    bool filterEnabled = true,
  }) {
    final paths = allRecordPaths(
      filterEnabled: filterEnabled,
      type: PathProviderType.record,
    );
    final visiblePaths = <RecordItem>[];

    for (final path in paths) {
      final requiredTypes = requiredBaselinesForPath(path);
      if (requiredTypes.isNotEmpty) {
        final matchingBaselines = <DetailResponse>[];
        bool allFound = true;
        for (final reqType in requiredTypes) {
          final b = baselines.cast<Stamp?>().firstWhere(
            (element) => element?.type == reqType,
            orElse: () => null,
          );
          if (b is DetailResponse) {
            matchingBaselines.add(b);
          } else {
            allFound = false;
            break;
          }
        }
        if (allFound) {
          visiblePaths.add(
            RecordItem(path: path, baselines: matchingBaselines),
          );
        }
      } else {
        visiblePaths.add(RecordItem(path: path));
      }
    }
    return visiblePaths;
  }

  List<ReviewItem> reviewPaths({
    DateTime? searchDate,
    required List<Stamp> stamps,
    required List<Stamp> baselines,
  }) {
    final paths = allRecordPaths(
      filterEnabled: true,
      type: PathProviderType.review,
    );
    final reviews = <ReviewItem>[];
    final date = searchDate ?? DateTime.now();

    for (final recordPath in paths) {
      final requiredTypes = requiredBaselinesForPath(recordPath);
      final matchingBaselines = <DetailResponse>[];
      if (requiredTypes.isNotEmpty) {
        bool allFound = true;
        for (final reqType in requiredTypes) {
          final b = baselines.cast<Stamp?>().firstWhere(
            (element) => element?.type == reqType,
            orElse: () => null,
          );
          if (b is DetailResponse) {
            matchingBaselines.add(b);
          } else {
            allFound = false;
            break;
          }
        }
        if (!allFound) continue;
      }

      if (recordPath.period == null) continue;
      final range = recordPath.period!.getRange(date);
      final searchType = recordPath.name;

      final valid = stamps.where((element) {
        final stampTime = DateTime.fromMillisecondsSinceEpoch(element.stamp);
        return element.type == searchType &&
            (stampTime.isBefore(range.end) ||
                stampTime.isAtSameMomentAs(range.end)) &&
            (stampTime.isAfter(range.start) ||
                stampTime.isAtSameMomentAs(range.start));
      }).toList();

      reviews.add(
        ReviewItem(
          path: recordPath,
          type: searchType,
          response: valid.isEmpty ? null : valid.first as DetailResponse,
          baselines: matchingBaselines,
        ),
      );
    }

    return reviews..sort(
      (first, second) => first.response == null
          ? -1
          : second.response == null
          ? 1
          : 0,
    );
  }

  Map<String, RecordPath> reviewPathsByType() {
    final paths = allRecordPaths(type: PathProviderType.review);
    return {for (final p in paths) p.name: p};
  }

  List<ReviewPeriod> reviewPeriods({
    required List<Stamp> stamps,
    required DateTimeRange displayRange,
  }) {
    final typeToPath = reviewPathsByType();
    final periods = <ReviewPeriod>[];

    for (final stamp in stamps) {
      if (stamp is! Response) continue;

      final RecordPath? path = typeToPath[stamp.type];
      if (path == null || path.period == null) continue;

      final DateTime stampDate = DateTime.fromMillisecondsSinceEpoch(
        stamp.stamp,
      );
      final DateTimeRange periodRange = path.period!.getRange(stampDate);

      if (!periodRange.start.isBefore(displayRange.end) ||
          !periodRange.end.isAfter(displayRange.start)) {
        continue;
      }

      periods.add(
        ReviewPeriod(
          type: stamp.type,
          range: periodRange,
          stamp: stamp,
          path: path,
        ),
      );
    }

    periods.sort((a, b) => a.range.start.compareTo(b.range.start));
    return periods;
  }

  List<QuestionNode> byType(String type) =>
      _nodes.values.where((n) => n.question.type == type).toList();

  List<PageLayout> pagesForPath(String pathName) =>
      _pagesByPath[pathName] ?? const [];

  Set<String> dependentsOf(String questionId) =>
      _dependents[questionId] ?? const {};

  DisplayConfig? displayConfigFor(String id) => _nodes[id]?.displayConfig;

  EntryConfig? entryConfigFor(String id) => _nodes[id]?.entryConfig;

  ValueNotifier<QuestionNodeState>? stateOf(String id) => _globalState[id];

  void recomputeGlobalState({
    Set<String>? enabledTypes,
    Set<String>? checkinTypes,
  }) {
    for (final entry in _nodes.entries) {
      final node = entry.value;
      final notifier = _globalState[entry.key];
      if (notifier == null) continue;

      final enabled =
          enabledTypes?.contains(node.question.type) ?? node.question.enabled;
      final checkin = checkinTypes?.contains(node.question.type) ?? false;

      final newState = QuestionNodeState(
        enabled: enabled,
        checkinRequired: checkin,
      );
      if (notifier.value != newState) {
        notifier.value = newState;
      }
    }
  }

  SessionGraph createSession({
    required String recordPathName,
    SessionData? initialData,
    List<Stamp> baselines = const [],
    Set<String>? whiteList,
  }) => SessionGraph(
    graph: this,
    initialData: initialData,
    pages: pagesForPath(recordPathName),
    baselines: baselines,
    whiteList: whiteList,
  );

  void dispose() {
    for (final notifier in _globalState.values) {
      notifier.dispose();
    }
  }
}
