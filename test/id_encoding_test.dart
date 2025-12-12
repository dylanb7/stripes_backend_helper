import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/baseline_id.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_resolver.dart';

void main() {
  group('sanitizeForId', () {
    test('lowercases and replaces spaces with hyphens', () {
      expect(sanitizeForId('Tonic Clonic'), 'tonic-clonic');
    });

    test('removes special characters', () {
      expect(sanitizeForId("It's a test!"), 'its-a-test');
    });

    test('handles multiple spaces', () {
      expect(sanitizeForId('Multiple   Spaces'), 'multiple-spaces');
    });

    test('preserves numbers', () {
      expect(sanitizeForId('Type 1'), 'type-1');
    });
  });

  group('parseGeneratedId', () {
    test('parses valid generated ID without version', () {
      final result = parseGeneratedId('seizure-freq::tonic-clonic');
      expect(result, isNotNull);
      expect(result!.templateId, 'seizure-freq');
      expect(result.value, 'tonic-clonic');
      expect(result.baselineVersion, isNull);
    });

    test('parses valid generated ID with baseline version', () {
      final result = parseGeneratedId('seizure-freq::tonic-clonic::v2');
      expect(result, isNotNull);
      expect(result!.templateId, 'seizure-freq');
      expect(result.value, 'tonic-clonic');
      expect(result.baselineVersion, 2);
    });

    test('returns null for non-generated ID', () {
      expect(parseGeneratedId('regular-uuid-id'), isNull);
    });

    test('returns null for malformed version', () {
      expect(parseGeneratedId('a::b::x3'), isNull);
    });

    test('returns null for too many parts', () {
      expect(parseGeneratedId('a::b::c::d'), isNull);
    });
  });

  group('BaselineId', () {
    test('create generates correct format', () {
      expect(
        BaselineId.create('seizure-types', 1),
        'baseline::seizure-types::v1',
      );
    });

    test('parse extracts components correctly', () {
      final result = BaselineId.parse('baseline::seizure-types::v3');
      expect(result, isNotNull);
      expect(result!.questionId, 'seizure-types');
      expect(result.version, 3);
    });

    test('parse returns null for non-baseline ID', () {
      expect(BaselineId.parse('regular-uuid'), isNull);
    });

    test('parse returns null for invalid version format', () {
      expect(BaselineId.parse('baseline::q1::x3'), isNull);
    });

    test('isBaseline correctly identifies baseline IDs', () {
      expect(BaselineId.isBaseline('baseline::q1::v1'), true);
      expect(BaselineId.isBaseline('regular-id'), false);
    });

    test('getLatestVersion returns highest version', () {
      final ids = [
        'baseline::seizure-types::v1',
        'baseline::seizure-types::v3',
        'baseline::seizure-types::v2',
        'baseline::other-q::v5',
      ];
      expect(BaselineId.getLatestVersion('seizure-types', ids), 3);
    });

    test('getLatestVersion returns 0 for no matches', () {
      expect(BaselineId.getLatestVersion('unknown', []), 0);
    });

    test('nextVersion increments correctly', () {
      final ids = ['baseline::q1::v1', 'baseline::q1::v2'];
      expect(BaselineId.nextVersion('q1', ids), 'baseline::q1::v3');
    });

    test('nextVersion starts at v1 for new question', () {
      expect(BaselineId.nextVersion('new-q', []), 'baseline::new-q::v1');
    });
  });
}
