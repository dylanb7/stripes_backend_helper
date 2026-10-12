import 'package:flutter/foundation.dart' show immutable;


@immutable
class PageSessionState {
  final bool visible;
  final bool requirementMet;
  final int pendingCount;
  final int answeredCount;
  final List<String> visibleQuestionIds;
  final List<String> newlyHiddenQuestionIds;

  const PageSessionState({
    required this.visible,
    required this.requirementMet,
    required this.pendingCount,
    this.answeredCount = 0,
    required this.visibleQuestionIds,
    this.newlyHiddenQuestionIds = const [],
  });

  bool get canProceed => pendingCount == 0 && requirementMet;

  int get totalCount => visibleQuestionIds.length;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PageSessionState &&
          visible == other.visible &&
          requirementMet == other.requirementMet &&
          pendingCount == other.pendingCount &&
          answeredCount == other.answeredCount &&
          _listEquals(visibleQuestionIds, other.visibleQuestionIds) &&
          _listEquals(newlyHiddenQuestionIds, other.newlyHiddenQuestionIds);

  @override
  int get hashCode => Object.hash(
        visible,
        requirementMet,
        pendingCount,
        answeredCount,
        Object.hashAll(visibleQuestionIds),
        Object.hashAll(newlyHiddenQuestionIds),
      );

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
