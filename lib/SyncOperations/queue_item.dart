class SyncQueueItem {
  final String id;
  final SyncAction action;
  final String payload;
  final int timestamp;
  final int retryCount;
  final String? subUserId;
  final bool deleteOnFailure;

  SyncQueueItem({
    required this.id,
    required this.action,
    required this.payload,
    required this.timestamp,
    this.retryCount = 0,
    this.subUserId,
    this.deleteOnFailure = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'action': action.name,
      'payload': payload,
      'timestamp': timestamp,
      'retry_count': retryCount,
      'sub_user_id': subUserId,
      'delete_on_failure': deleteOnFailure ? 1 : 0,
    };
  }

  factory SyncQueueItem.fromMap(Map<String, dynamic> map) {
    return SyncQueueItem(
      id: map['id'],
      action: SyncAction.fromString(map['action']),
      payload: map['payload'],
      timestamp: map['timestamp'],
      retryCount: map['retry_count'] ?? 0,
      subUserId: map['sub_user_id'],
      deleteOnFailure: (map['delete_on_failure'] as int?) == 1,
    );
  }
}

enum SyncAction {
  create,
  update,
  delete,
  setTestState,
  cancelTest;

  String get name {
    switch (this) {
      case SyncAction.create:
        return 'create';
      case SyncAction.update:
        return 'update';
      case SyncAction.delete:
        return 'delete';
      case SyncAction.setTestState:
        return 'setTestState';
      case SyncAction.cancelTest:
        return 'cancelTest';
    }
  }

  static SyncAction fromString(String value) {
    return SyncAction.values.firstWhere(
      (e) => e.name == value,
      orElse: () => throw ArgumentError('Invalid SyncAction: $value'),
    );
  }
}

enum SyncType {
  detailResponse,
  blueDyeResponse,
  subUser,
  blueDyeState;

  String get name {
    switch (this) {
      case SyncType.detailResponse:
        return 'DetailResponse';
      case SyncType.blueDyeResponse:
        return 'BlueDyeResponse';
      case SyncType.subUser:
        return 'SubUser';
      case SyncType.blueDyeState:
        return 'BlueDyeState';
    }
  }

  static SyncType fromString(String value) {
    return SyncType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => throw ArgumentError('Invalid SyncType: $value'),
    );
  }
}
