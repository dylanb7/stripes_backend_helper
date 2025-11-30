import 'package:equatable/equatable.dart';

import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';

abstract class TestEnrollmentSource {


  TestEnrollmentSource();

  Future<List<TestEnrollment>> loadAllEnrollments();
  
  Future<void> updateEnrollment(TestEnrollment enrollment); 
}

class TestsRepo {

  final TestEnrollmentSource source;

  final BehaviorSubject<List<TestEnrollment>> _enrollmentsSubject =
      BehaviorSubject();

  TestsRepo({required this.source}) {
    _loadInEnrollments();
  }

  _loadInEnrollments() async {
    final List<TestEnrollment> loadedEnrollments = await source.loadAllEnrollments();
    _enrollmentsSubject.add(loadedEnrollments);
  }

  Stream<List<TestEnrollment>> get enrollments => _enrollmentsSubject.stream;

  List<Question> getRecordAdditions(BuildContext context, String logType) {
    List<Question> additions = [];

    final activeEnrollments =
        _enrollmentsSubject.value.where((e) => e.status == TestStatus.active);

    /*for (final enrollment in activeEnrollments) {
      final protocol =
          protocols.firstWhere((p) => p.id == enrollment.protocolId);

      if (protocol.triggerTypes.contains(logType)) {
        final currentPhaseId = enrollment.metadata['currentPhaseId'];

        final activePhase = protocol.phases.firstWhere(
            (p) => p.id == currentPhaseId,
            orElse: () => protocol.phases.first);

        additions.addAll(activePhase.injectedQuestions);
      }
    }*/
    return additions;
  }
}

@immutable
class TestProtocol extends Equatable {
  final String id;
  final String name;
  final String description;

  final List<String> triggerTypes;

  final Duration duration;

  final TestContent content;

  final List<TestPhase> phases;

  const TestProtocol({
    required this.id,
    required this.name,
    required this.description,
    required this.triggerTypes,
    required this.duration,
    required this.content,
    required this.phases,
  });

  factory TestProtocol.fromJson(Map<String, dynamic> json) {
    return TestProtocol(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] ?? '',
      triggerTypes: (json['triggerTypes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      duration: Duration(seconds: json['durationSeconds'] ?? 0),
      content: TestContent.fromJson(json['content'] ?? {}),
      phases: (json['phases'] as List<dynamic>?)
              ?.map((e) => TestPhase.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'triggerTypes': triggerTypes,
      'durationSeconds': duration.inSeconds,
      'content': content.toJson(),
      'phases': phases.map((p) => p.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [id, name, triggerTypes, phases];
}

class TestContent extends Equatable {
  final String instructionMarkdown;
  final String consentMarkdown;
  final String completionMarkdown;

  const TestContent({
    this.instructionMarkdown = '',
    this.consentMarkdown = '',
    this.completionMarkdown = '',
  });

  factory TestContent.fromJson(Map<String, dynamic> json) {
    return TestContent(
      instructionMarkdown: json['instructionMarkdown'] ?? '',
      consentMarkdown: json['consentMarkdown'] ?? '',
      completionMarkdown: json['completionMarkdown'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'instructionMarkdown': instructionMarkdown,
      'consentMarkdown': consentMarkdown,
      'completionMarkdown': completionMarkdown,
    };
  }

  @override
  List<Object?> get props => [instructionMarkdown, consentMarkdown];
}

class TestPhase extends Equatable {
  final String id;
  final String name;

  final List<Question> injectedQuestions;

  const TestPhase({
    required this.id,
    required this.name,
    required this.injectedQuestions,
  });

  factory TestPhase.fromJson(Map<String, dynamic> json) {
    return TestPhase(
      id: json['id'] as String,
      name: json['name'] ?? 'Standard',
      injectedQuestions: (json['questions'] as List<dynamic>?)
              ?.map((q) => Question.fromJson(q as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'questions': injectedQuestions.map((q) => q.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [id, injectedQuestions];
}

enum TestStatus {
  pending,
  active,
  completed,
  withdrawn,
}

@immutable
class TestEnrollment extends Equatable {
  final String id;
  final String userId;
  final String protocolId;

  final DateTime startDate;
  final DateTime? endDate;
  final TestStatus status;

  final Map<String, dynamic> metadata;

  const TestEnrollment({
    required this.id,
    required this.userId,
    required this.protocolId,
    required this.startDate,
    this.endDate,
    this.status = TestStatus.pending,
    this.metadata = const {},
  });

  String? get currentPhaseId => metadata['currentPhaseId'] as String?;

  factory TestEnrollment.fromJson(Map<String, dynamic> json) {
    return TestEnrollment(
      id: json['id'],
      userId: json['userId'],
      protocolId: json['protocolId'],
      startDate: DateTime.parse(json['startDate']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      status: TestStatus.values.firstWhere((e) => e.name == json['status'],
          orElse: () => TestStatus.active),
      metadata: json['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'protocolId': protocolId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'status': status.name,
      'metadata': metadata,
    };
  }

  TestEnrollment copyWith({
    String? id,
    String? userId,
    String? protocolId,
    DateTime? startDate,
    DateTime? endDate,
    TestStatus? status,
    Map<String, dynamic>? metadata,
  }) {
    return TestEnrollment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      protocolId: protocolId ?? this.protocolId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [id, userId, protocolId, status, metadata];
}
