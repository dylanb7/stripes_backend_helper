import 'package:flutter/foundation.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/baseline_id.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_resolver.dart';
import 'package:stripes_backend_helper/RepositoryBase/StampBase/stamp.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/Graph/page_session_state.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/Graph/question_graph.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/Graph/question_node.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/Graph/question_session_state.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_repo_base.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/session_data.dart';

class SessionGraph extends ChangeNotifier {
  final QuestionGraph _graph;
  final List<PageLayout> _pages;
  final Set<String>? _whiteList;
  final List<Stamp> baselines;

  SessionData _data;

  final Map<String?, ValueNotifier<PageSessionState>> _pageState = {};

  final Map<String, ValueNotifier<QuestionSessionState>> _questionState = {};

  final Map<String?, Set<String>> _previouslyVisibleByPage = {};

  SessionGraph({
    required QuestionGraph graph,
    SessionData? initialData,
    required List<PageLayout> pages,
    this.baselines = const [],
    Set<String>? whiteList,
  }) : _graph = graph,
       _data = initialData ?? const SessionData(),
       _pages = pages,
       _whiteList = whiteList {
    _initializeState();
  }

  /// Helper to return the baseline [Stamp] for a specific question (by id).
  Stamp? baselineForQuestion(String questionId) {
    final q = _graph.node(questionId)?.question;
    if (q?.fromBaseline == null) return null;
    return _findBaselineContext(q!.fromBaseline!);
  }

  /// Helper to return all baseline [Stamp] objects active on a [page].
  List<Stamp> baselinesForPage(PageLayout page) {
    final result = <Stamp>{};
    for (final qid in page.questionIds) {
      final b = baselineForQuestion(qid);
      if (b != null) result.add(b);
    }
    return result.toList();
  }

  /// Returns a map of questionId -> matching baseline [Stamp].
  Map<String, Stamp> get questionBaselineMap {
    final map = <String, Stamp>{};
    for (final qid in _questionState.keys) {
      final b = baselineForQuestion(qid);
      if (b != null) {
        map[qid] = b;
      }
    }
    return map;
  }

  Stamp? _findBaselineContext(String fromBaselineType) {
    if (baselines.isEmpty) return null;
    for (final ctx in baselines) {
      if (ctx.type == fromBaselineType) {
        return ctx;
      }
    }
    return baselines.first;
  }

  factory SessionGraph.fromData({
    required QuestionGraph graph,
    required SessionData data,
    required List<PageLayout> pages,
    List<Stamp> baselines = const [],
    Set<String>? whiteList,
  }) => SessionGraph(
    graph: graph,
    initialData: data,
    pages: pages,
    baselines: baselines,
    whiteList: whiteList,
  );

  SessionData get data => _data;

  Map<String, Response> get responses => _data.responses;

  String? get editId => _data.editId;

  DateTime? get submitTime => _data.submitTime;

  set submitTime(DateTime? dateTime) {
    if (_data.submitTime != dateTime) {
      _data = _data.copyWith(submitTime: dateTime);
      notifyListeners();
    }
  }

  String? get description => _data.description;

  set description(String? desc) {
    if (_data.description != desc) {
      _data = _data.copyWith(description: desc);
      notifyListeners();
    }
  }

  bool get tried => _data.tried;

  set tried(bool val) {
    if (_data.tried != val) {
      _data = _data.copyWith(tried: val);
      notifyListeners();
    }
  }

  Response? fromQuestion(Question question) => _data.fromQuestion(question);

  Response? responseFor(String questionId) => _data.responseFor(questionId);

  void setResponse(Question question, {Response? response}) {
    final newResponses = Map<String, Response>.from(_data.responses);
    if (response == null) {
      newResponses.remove(question.id);
    } else {
      newResponses[question.id] = response;
    }
    _data = _data.copyWith(responses: newResponses);

    recomputeFrom(question.id);
    notifyListeners();
  }

  void addResponse(Response response) =>
      setResponse(response.question, response: response);

  void removeResponse(Question question) =>
      setResponse(question, response: null);

  List<PageLayout> get allPages => List.unmodifiable(_pages);

  List<PageLayout> get visiblePages =>
      _pages.where((p) => _pageState[p.id]?.value.visible ?? false).toList();

  bool get canSubmit =>
      !_data.hasUnresolvedResponses &&
      visiblePages.every((p) => _pageState[p.id]?.value.canProceed ?? false);

  /// Creates a final DetailResponse snapshot ready for submission/persistence,
  /// automatically encoding generated question definitions.
  DetailResponse createDetailResponse({
    required String detailType,
    String? id,
  }) {
    final DateTime submissionTime = submitTime ?? DateTime.now();
    if (_data.hasUnresolvedResponses) {
      throw StateError(
        'Load compatible question definitions before editing this record',
      );
    }
    return DetailResponse(
      id: id ?? editId,
      description: description,
      responses: responses.values
          .map((res) => res.encodeGeneratedQuestion())
          .toList(growable: false),
      stamp: submissionTime.millisecondsSinceEpoch,
      detailType: detailType,
    );
  }

  /// Prints a human-readable summary of internal SessionGraph state
  /// (pages, question node visibility, responses, and submit readiness).
  void dumpDebugInfo([void Function(String message)? printer]) {
    final printFn = printer ?? (String msg) => debugPrint(msg);

    final buf = StringBuffer();
    buf.writeln('═══ [SessionGraph Debug Dump] ═══');
    buf.writeln('  Edit ID: ${editId ?? "None (New Entry)"}');
    buf.writeln('  Submit Time: ${submitTime ?? "Now"}');
    buf.writeln('  Can Submit: $canSubmit');
    buf.writeln(
      '  Total Pages: ${_pages.length} | Visible Pages: ${visiblePages.length}',
    );
    buf.writeln('  Total Responses: ${responses.length}');

    buf.writeln('\n── Pages State ──');
    for (int i = 0; i < _pages.length; i++) {
      final page = _pages[i];
      final state = _pageState[page.id]?.value;
      buf.writeln('  [$i] Page ID: ${page.id ?? "<none>"}');
      if (state == null) {
        buf.writeln('      State: <uninitialized>');
      } else {
        buf.writeln('      Visible: ${state.visible}');
        buf.writeln('      Requirement Met: ${state.requirementMet}');
        buf.writeln('      Pending Required Count: ${state.pendingCount}');
        buf.writeln('      Can Proceed: ${state.canProceed}');
        buf.writeln('      Visible Question IDs: ${state.visibleQuestionIds}');
      }
    }

    buf.writeln('\n── Questions Node State ──');
    for (final entry in _questionState.entries) {
      final qid = entry.key;
      final qState = entry.value.value;
      final response = responses[qid];
      buf.writeln('  • Question [$qid] (${qState.resolvedQuestion.type}):');
      buf.writeln(
        '      Visible: ${qState.visible} | Valid: ${qState.valid} | Answered: ${qState.answered}',
      );
      if (qState.resolvedQuestion.prompt.isNotEmpty) {
        buf.writeln('      Prompt: "${qState.resolvedQuestion.prompt}"');
      }
      if (response != null) {
        buf.writeln('      Response Value: $response');
      }
    }
    buf.writeln('═════════════════════════════════');

    printFn(buf.toString());
  }

  ValueNotifier<PageSessionState>? pageStateOf(String? pageId) =>
      _pageState[pageId];

  ValueNotifier<QuestionSessionState>? questionStateOf(String questionId) =>
      _questionState[questionId];

  bool isQuestionValid(Question question) {
    final bool answered = _data.responses.containsKey(question.id);
    return (!question.isRequired || answered) &&
        (question.requirement?.eval(_data, contextId: question.id) ?? true);
  }

  PageSessionState? validatePage(int index) {
    final visible = visiblePages;
    if (index < 0 || index >= visible.length) return null;
    return _pageState[visible[index].id]?.value;
  }

  List<String> visibleQuestionsForPage(int index) {
    final visible = visiblePages;
    if (index < 0 || index >= visible.length) return const [];
    return _pageState[visible[index].id]?.value.visibleQuestionIds ?? const [];
  }

  void recomputeFrom(String changedQuestionId) {
    final generatedId = parseGeneratedId(changedQuestionId);
    final sourceQuestionId = generatedId?.templateId ?? changedQuestionId;

    _recomputeQuestion(sourceQuestionId);

    final affected = _graph.dependentsOf(sourceQuestionId);
    for (final depId in affected) {
      _recomputeQuestion(depId);
    }

    for (final page in _pages) {
      _recomputePage(page);
    }
  }

  void _initializeState() {
    final whiteList = _whiteList;
    for (final page in _pages) {
      for (final qid in page.questionIds) {
        if (whiteList != null && !whiteList.contains(qid)) continue;
        final node = _graph.node(qid);
        if (node == null) continue;
        if (!_questionState.containsKey(qid)) {
          _questionState[qid] = ValueNotifier(_computeQuestionState(node));
        }
      }
      final pageState = _computePageState(page);
      _pageState[page.id] = ValueNotifier(pageState);
      _previouslyVisibleByPage[page.id] = pageState.visibleQuestionIds.toSet();
    }
  }

  void _recomputeQuestion(String questionId) {
    final node = _graph.node(questionId);
    if (node == null) return;
    final notifier = _questionState[questionId];
    if (notifier == null) return;

    final newState = _computeQuestionState(node);
    if (notifier.value != newState) {
      notifier.value = newState;
    }
  }

  void _recomputePage(PageLayout page) {
    final notifier = _pageState[page.id];
    if (notifier == null) return;

    final newState = _computePageState(page);

    final previouslyVisible =
        _previouslyVisibleByPage[page.id] ?? const <String>{};
    final currentlyVisible = newState.visibleQuestionIds.toSet();
    final newlyHidden = previouslyVisible.difference(currentlyVisible);

    _previouslyVisibleByPage[page.id] = currentlyVisible;

    if (newlyHidden.isNotEmpty) {
      final newResponses = Map<String, Response>.from(_data.responses);
      var changed = false;
      for (final hiddenId in newlyHidden) {
        if (newResponses.containsKey(hiddenId)) {
          if (newResponses[hiddenId] is! UnresolvedResponse) {
            newResponses.remove(hiddenId);
          }
          changed = true;
        }
      }
      if (changed) {
        _data = _data.copyWith(responses: newResponses);
      }
    }

    if (notifier.value != newState) {
      notifier.value = newState;
    }
  }

  QuestionSessionState _computeQuestionState(QuestionNode node) {
    final Question q = node.question;
    List<Question> resolvedQuestions = [q];

    if (q.fromBaseline != null) {
      final matchingBaseline = _findBaselineContext(q.fromBaseline!);
      if (matchingBaseline != null && matchingBaseline is Response) {
        final int version = matchingBaseline.id != null
            ? (BaselineId.parse(matchingBaseline.id!)?.version ?? 1)
            : 1;
        resolvedQuestions = q.resolveFromBaseline(
          baseline: matchingBaseline,
          baselineVersion: version,
        );
      }
    } else if (q.transform != null && _data.responses.isNotEmpty) {
      resolvedQuestions = q.resolve(
        current: DetailResponse(
          responses: _data.responses.values.toList(growable: false),
          stamp: DateTime.now().millisecondsSinceEpoch,
          detailType: 'current_session',
        ),
      );
    }

    if (resolvedQuestions.isEmpty) resolvedQuestions = [q];
    final bool answered = resolvedQuestions.every(
      (question) => _data.responses.containsKey(question.id),
    );
    return QuestionSessionState(
      visible: q.dependsOn?.eval(_data) ?? true,
      valid: resolvedQuestions.every(isQuestionValid),
      answered: answered,
      resolvedQuestion: resolvedQuestions.length == 1
          ? resolvedQuestions.single
          : q,
    );
  }

  PageSessionState _computePageState(PageLayout page) {
    final bool pageVisible = page.dependsOn.eval(_data);

    if (!pageVisible) {
      return const PageSessionState(
        visible: false,
        requirementMet: true,
        pendingCount: 0,
        visibleQuestionIds: [],
      );
    }

    final whiteList = _whiteList;
    final List<String> visibleQuestionIds = [];
    for (final qid in page.questionIds) {
      if (whiteList != null && !whiteList.contains(qid)) continue;
      final qState = _questionState[qid]?.value;
      if (qState == null || qState.visible) {
        visibleQuestionIds.add(qid);
      }
    }

    final bool requirementMet = page.requirement.eval(_data);

    final pageQids = visibleQuestionIds.toSet();
    int pendingCount = 0;
    int answeredCount = 0;

    for (final qid in pageQids) {
      final qState = _questionState[qid]?.value;
      if (qState != null) {
        if (!qState.valid) pendingCount++;
        if (qState.answered) answeredCount++;
      }
    }

    return PageSessionState(
      visible: true,
      requirementMet: requirementMet,
      pendingCount: pendingCount,
      answeredCount: answeredCount,
      visibleQuestionIds: visibleQuestionIds,
    );
  }

  @override
  void dispose() {
    for (final notifier in _pageState.values) {
      notifier.dispose();
    }
    for (final notifier in _questionState.values) {
      notifier.dispose();
    }
    super.dispose();
  }
}
