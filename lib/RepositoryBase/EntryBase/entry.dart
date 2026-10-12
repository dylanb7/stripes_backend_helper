import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

enum InputCategory {
  /// High frequency, low burden (BM, meal, pain)
  event,

  /// Medium frequency, medium burden (checkin)
  form,

  /// Initial or study baseline forms
  baseline,

  /// Low frequency, high burden (medication change, regression)
  landmark,

  /// Test-specific entries (blue dye test/response)
  test,
}

enum TimeOfDayEntry {
  exact('exact'),
  morning('morning'),
  afternoon('afternoon'),
  evening('evening'),
  night('night'),
  notSure('not_sure');

  final String value;

  const TimeOfDayEntry(this.value);

  static TimeOfDayEntry? fromString(String value) {
    for (final tod in TimeOfDayEntry.values) {
      if (tod.value == value) return tod;
    }
    return null;
  }

  @override
  String toString() => value;
}

/// A unified data record that replaces DetailResponse, BlueDyeResponse,
/// BlueDyeTest, BlueDyeLog, and Response.
///
/// - [entityType] holds the [InputCategory] name (e.g. "event", "form", "baseline", "test", "landmark").
/// - [data] holds the type-specific JSON payload. The specific subtype string
///   (like "category.BM" or "blue_dye_test") is stored inside [data['type']].
/// - [sessionId] links entries from a single record flow (e.g. blue dye test)
@immutable
class Entry with EquatableMixin {
  final String? id;
  final String subUserId;
  final String? group;

  /// When the symptom/event occurred, normalized to UTC. Localize at the UI.
  final DateTime stamp;

  /// The broad UX category: 'event', 'form', 'baseline', 'landmark', or 'test'.
  final String entityType;

  /// The type-specific data payload.
  final Map<String, dynamic> data;

  /// How precise the timestamp is. Null treated as [TimeOfDayEntry.exact].
  final TimeOfDayEntry? timeOfDay;

  /// Groups entries created in a single record flow (e.g. blue dye test)
  final String? sessionId;

  /// When this entry was actually created on-device.
  final DateTime? createdAt;

  /// When this entry was last updated.
  final DateTime? updatedAt;

  Entry({
    this.id,
    required this.subUserId,
    this.group,
    required DateTime stamp,
    required this.entityType,
    required this.data,
    this.timeOfDay,
    this.sessionId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : stamp = stamp.toUtc(),
       createdAt = createdAt?.toUtc(),
       updatedAt = updatedAt?.toUtc();

  /// Resolved [InputCategory], or null if [entityType] is not a valid category.
  InputCategory get category => InputCategory.values.firstWhere(
    (c) => c.name == entityType,
    orElse: () => InputCategory.event,
  );

  /// Resolved specific subtype string from data['type'] (e.g. "category.BM", "blue_dye_test").
  String? get subtype => data['type'] as String?;

  Entry copyWith({
    String? id,
    String? subUserId,
    String? group,
    DateTime? stamp,
    String? entityType,
    Map<String, dynamic>? data,
    TimeOfDayEntry? timeOfDay,
    String? sessionId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Entry(
      id: id ?? this.id,
      subUserId: subUserId ?? this.subUserId,
      group: group ?? this.group,
      stamp: stamp ?? this.stamp,
      entityType: entityType ?? this.entityType,
      data: data ?? this.data,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      sessionId: sessionId ?? this.sessionId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subUserId': subUserId,
      'group': group,
      'stamp': stamp.toIso8601String(),
      'entityType': entityType,
      'data': data,
      'timeOfDay': timeOfDay?.value,
      'sessionId': sessionId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory Entry.fromJson(Map<String, dynamic> json) {
    return Entry(
      id: json['id'] as String?,
      subUserId: json['subUserId'] as String,
      group: json['group'] as String?,
      stamp: DateTime.parse(json['stamp'] as String),
      entityType: json['entityType'] as String,
      data: json['data'] is Map
          ? Map<String, dynamic>.from(json['data'] as Map)
          : <String, dynamic>{},
      timeOfDay: json['timeOfDay'] != null
          ? TimeOfDayEntry.fromString(json['timeOfDay'] as String)
          : null,
      sessionId: json['sessionId'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [
    id,
    subUserId,
    group,
    stamp,
    entityType,
    data,
    timeOfDay,
    sessionId,
    createdAt,
    updatedAt,
  ];
}
