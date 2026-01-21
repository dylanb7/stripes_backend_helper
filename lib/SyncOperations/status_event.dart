import 'package:stripes_backend_helper/RepositoryBase/repo_result.dart';
import 'package:stripes_backend_helper/SyncOperations/queue_item.dart';

class SyncStatusEvent<T> {
  final String id;
  final SyncAction action;
  final RepoResult<T> result;
  final bool isRetrying;

  SyncStatusEvent({
    required this.id,
    required this.action,
    required this.result,
    this.isRetrying = false,
  });

  @override
  String toString() {
    if (result is Success) {
      return 'SyncStatusEvent(id: $id, action: ${action.name}, type: Success)';
    } else {
      final f = result as Failure;
      return 'SyncStatusEvent(id: $id, action: ${action.name}, type: Failure, error: ${f.error})';
    }
  }
}
