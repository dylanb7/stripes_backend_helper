import 'package:stripes_backend_helper/SyncOperations/queue_item.dart';
import 'package:stripes_backend_helper/SyncOperations/status_event.dart';

abstract class SyncManagerBase {
  Stream<List<SyncQueueItem>> get queueStream;

  Stream<SyncStatusEvent> get statusStream;

  Future<void> retry();

  Future<void> retryItem(String id);
}
