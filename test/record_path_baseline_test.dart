import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_repo_base.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_resolver.dart';

void main() {
  group('RecordPath fromBaseline', () {
    test('serialization includes fromBaseline', () {
      final path = RecordPath(
        name: 'Test Path',
        pages: [],
        fromBaseline: 'TestBaselineType',
        isBaseline: false,
      );

      final json = path.toJson();
      expect(json['fromBaseline'], 'TestBaselineType');

      final deserialized = RecordPath.fromJson(json);
      expect(deserialized.fromBaseline, 'TestBaselineType');
      expect(deserialized, path);
    });

    test('filtering logic simulation', () {
      // Simulate a list of paths
      final paths = [
        RecordPath(name: 'Regular Path', pages: []),
        RecordPath(
            name: 'Baseline Dependent Path', pages: [], fromBaseline: 'Pain'),
        RecordPath(
            name: 'Another Dependent Path', pages: [], fromBaseline: 'Mood'),
      ];

      // Simulate available baselines (e.g. from a repository)
      final availableBaselines = <String>{'Pain'};

      // Filter logic: Show path if fromBaseline is null OR if fromBaseline is in availableBaselines
      final visiblePaths = paths.where((path) {
        if (path.fromBaseline == null) return true;
        return availableBaselines.contains(path.fromBaseline);
      }).toList();

      expect(visiblePaths.length, 2);
      expect(visiblePaths.any((p) => p.name == 'Regular Path'), true);
      expect(
          visiblePaths.any((p) => p.name == 'Baseline Dependent Path'), true);
      expect(
          visiblePaths.any((p) => p.name == 'Another Dependent Path'), false);
    });
  });

  group('Question resolveFromBaseline', () {
    test('resolves correctly when fromBaseline matches', () {
      // Create a question that depends on a baseline
      const question = FreeResponse(
        id: 'q1',
        prompt: 'How is your {value}?',
        type: 'Test',
        fromBaseline: 'TestBaseline',
        transform: '{"type":"generateForEach","sourceId":"sourceQ"}',
      );

      // Create a baseline response
      // Typically the baseline response contains the source question response
      // Let's assume the baseline has a response for "sourceQ"

      // We need a dummy baseline response.
      // Since Response is abstract and uses Question, we construct a simple chain.

      final sourceQuestion =
          FreeResponse(id: 'sourceQ', prompt: 'Source', type: 'Test');
      final sourceResp = OpenResponse(
          question: sourceQuestion, stamp: 123, response: 'Headache');

      // Wrapper response acting as baseline (e.g. DetailResponse)
      final baseline = DetailResponse(
          responses: [sourceResp], stamp: 123, detailType: 'TestBaseline');

      // Resolve
      final resolved = question.resolveFromBaseline(baseline: baseline);

      // Expect transformation to happen (generateForEach -> Headache)
      expect(resolved.length, 1);
      expect(resolved.first.prompt, 'How is your Headache?');
      expect(resolved.first.id, contains('headache'));
    });

    test('resolveFromBaseline returns self if fromBaseline is missing', () {
      const question = FreeResponse(
        id: 'q1',
        prompt: 'Normal',
        type: 'Test',
        // No fromBaseline
        transform: '{"type":"generateForEach","sourceId":"sourceQ"}',
      );

      final baseline =
          DetailResponse(responses: [], stamp: 1, detailType: 'Any');

      final resolved = question.resolveFromBaseline(baseline: baseline);
      expect(resolved.length, 1);
      expect(resolved.first, question);
    });

    test('resolveFromBaseline populates MapChoices for AllThatApply', () {
      const question = AllThatApply(
        id: 'q2a',
        prompt: 'Which seizure types have increased?',
        type: 'Seizure',
        choices: [], // Empty initially
        fromBaseline: 'SeizureBaseline',
        transform: '{"type":"mapChoices","sourceId":"baselineTypes"}',
      );

      // Baseline response containing the types from baseline
      final baselineQuestion = AllThatApply(
          id: 'baselineTypes',
          prompt: 'Select types',
          type: 'Seizure',
          choices: ['Type A', 'Type B', 'Type C']);

      final baselineResp = AllResponse(
          question: baselineQuestion,
          stamp: 1,
          responses: [0, 2] // Selected Type A and Type C
          );

      final baseline = DetailResponse(
          responses: [baselineResp], stamp: 1, detailType: 'SeizureBaseline');

      final resolved = question.resolveFromBaseline(baseline: baseline);

      expect(resolved.length, 1);
      final resolvedQ = resolved.first as AllThatApply;
      expect(resolvedQ.choices.length, 2);
      expect(resolvedQ.choices, contains('Type A'));
      expect(resolvedQ.choices, contains('Type C'));
    });
  });
}
