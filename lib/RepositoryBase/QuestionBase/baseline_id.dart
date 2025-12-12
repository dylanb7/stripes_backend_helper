/// Utilities for baseline response ID encoding/decoding.
/// Format: baseline::{questionId}::v{version}
/// Example: baseline::seizure-types::v1
class BaselineId {
  static const String prefix = 'baseline';
  static const String separator = '::';

  BaselineId._();

  static String create(String questionId, int version) {
    return '$prefix$separator$questionId${separator}v$version';
  }

  static ({String questionId, int version})? parse(String id) {
    if (!id.startsWith('$prefix$separator')) return null;
    final parts = id.split(separator);
    if (parts.length != 3) return null;
    final versionStr = parts[2];
    if (!versionStr.startsWith('v')) return null;
    final version = int.tryParse(versionStr.substring(1));
    if (version == null) return null;
    return (questionId: parts[1], version: version);
  }

  static bool isBaseline(String id) => id.startsWith('$prefix$separator');

  static int getLatestVersion(String questionId, Iterable<String> allIds) {
    int latest = 0;
    for (final id in allIds) {
      final parsed = parse(id);
      if (parsed != null && parsed.questionId == questionId) {
        if (parsed.version > latest) latest = parsed.version;
      }
    }
    return latest;
  }

  static String nextVersion(String questionId, Iterable<String> existingIds) {
    final current = getLatestVersion(questionId, existingIds);
    return create(questionId, current + 1);
  }
}
