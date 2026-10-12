import 'package:flutter_test/flutter_test.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_loader.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_resolver.dart';
import 'package:stripes_backend_helper/stripes_backend_helper.dart';
import 'package:yaml/yaml.dart';

class _TestQuestionHome extends QuestionHome {
  _TestQuestionHome(Map<String, Question> qMap) {
    all = qMap;
  }

  @override
  Map<String, List<Question>> byType() => {};
}

const String _prodQuestionsYaml = '''
schemaVersion: 1.0.0

questions:
  - id: q1
    promptKey: pain.q1.stomach_pain
    type: category.PAIN
    kind: Check

  - id: q2
    promptKey: nb.q2.no_sleep
    type: category.NB
    kind: Check

  - id: q3
    promptKey: bm.q3.activity_after_bm
    type: category.BM
    kind: Check

  - id: q4
    promptKey: bm.q4.average_bm_type
    type: category.BM
    kind: Numeric
    requirement:
      exists: true
    min: 1
    max: 7

  - id: q6
    promptKey: bm.q6.pain_with_bm
    type: category.BM
    kind: Numeric
    requirement:
      exists: true
    min: 0
    max: 10

  - id: q7
    promptKey: bm.q7.could_not_reach_toilet
    type: category.BM
    kind: Check

  - id: q8
    promptKey: bm.q8.struggled_bm
    type: category.BM
    kind: Check

  - id: q9
    promptKey: bm.q9.black_stool
    type: category.BM
    kind: Check

  - id: q10
    promptKey: reflux.q10.rechewed_food
    type: category.REFLUX
    kind: Check

  - id: q11
    promptKey: reflux.q11.vomited_food
    type: category.REFLUX
    kind: Check

  - id: q12
    promptKey: reflux.q12.vomit_attempt
    type: category.REFLUX
    kind: Check

  - id: q13
    promptKey: nb.q13.woke_up_early
    type: category.NB
    kind: Check

  - id: q14
    promptKey: pain.q14.head_tilt_back_arch
    type: category.PAIN
    kind: Check

  - id: q18
    promptKey: pain.q18.abdomen_pressure
    type: category.PAIN
    kind: Check

  - id: q19
    promptKey: reflux.q19.gagging_after_swallow
    type: category.REFLUX
    kind: Check

  - id: q20
    promptKey: reflux.q20.food_refusal
    type: category.REFLUX
    kind: Check

  - id: q21
    promptKey: nb.q21.falling_asleep
    type: category.NB
    kind: Check

  - id: q22
    promptKey: nb.q22.staying_asleep
    type: category.NB
    kind: Check

  - id: q23
    promptKey: nb.q23.toss_turn_sleep
    type: category.NB
    kind: Check

  - id: q24
    promptKey: nb.q24.irritability
    type: category.NB
    kind: Check

  - id: q25
    promptKey: nb.q25.aggressive_behavior
    type: category.NB
    kind: Check

  - id: q26
    promptKey: nb.q26.self_injury
    type: category.NB
    kind: Check

  - id: q27
    promptKey: pain.q27.teeth_grit
    type: category.PAIN
    kind: Check

  - id: q28
    promptKey: pain.q28.pain_noises
    type: category.PAIN
    kind: Check

  - id: q29
    promptKey: bm.q29.lost_control
    type: category.BM
    kind: Check

  - id: q30
    promptKey: bm.q30.gas
    type: category.BM
    kind: Check

  - id: q31
    promptKey: bm.q31.bloating
    type: category.BM
    kind: Check

  - id: q32
    promptKey: pain.q32.verbal_pain
    type: category.PAIN
    kind: Check

  - id: Pain-Rating
    promptKey: pain.rating.value
    type: category.PAIN
    kind: Numeric
    requirement:
      exists: true

  - id: Pain-Location
    promptKey: pain.location.value
    type: category.PAIN
    kind: AllThatApply
    requirement:
      exists: true
    choices:
      - pain.location.value.unknown
      - pain.location.value.upper_left
      - pain.location.value.top
      - pain.location.value.upper_right
      - pain.location.value.left
      - pain.location.value.center
      - pain.location.value.right
      - pain.location.value.bottom_left
      - pain.location.value.bottom
      - pain.location.value.bottom_right

  - id: Meal-Type
    promptKey: Meal Time.Meal-Type
    type: category.Meal-Time
    kind: MultipleChoice
    choices:
      - meal.breakfast
      - meal.lunch
      - meal.dinner
      - meal.snack
      - meal.other

  - id: BlueDyeQuestion
    promptKey: bm.blue_dye
    type: category.BM
    kind: MultipleChoice
    requirement:
      exists: true
    isAddition: true
    choices:
      - common.yes
      - common.no

  - id: seizure-q1
    promptKey: seizure.q1.had_seizures_past_2_years
    type: category.SEIZURE_BASELINE
    requirement:
      exists: true
    kind: MultipleChoice
    isBaseline: true
    choices:
       - common.yes
       - common.no

  - id: seizure-q2
    promptKey: seizure.q2.seizure_types
    type: category.SEIZURE_BASELINE
    kind: AllThatApply
    isBaseline: true
    transform:
      type: generateForEach
      generated:
        prompt: "seizure.q2.generated_frequency"
        type: MultipleChoice
        requirement: "(exists:)all"
        choices:
          - seizure.frequency.less_than_1_per_month
          - seizure.frequency.1_week_to_1_month
          - seizure.frequency.1_day_to_1_week
          - seizure.frequency.more_than_1_per_day
          - seizure.frequency.more_than_10_per_day
    choices:
      - seizure.type.generalized_tonic_clonic
      - seizure.type.absence_staring_spells
      - seizure.type.drop_attacks_atonic
      - seizure.type.focal
      - seizure.type.other

  - id: seizure-q2-other
    promptKey: seizure.q2.describe_other
    type: category.SEIZURE_BASELINE
    kind: FreeResponse
    requirement:
      exists: true
    isBaseline: true
    dependsOn:
      oneOf:
        - questionId: seizure-q2
          containsIndex: 4

  - id: seizure-q3
    promptKey: seizure.q3.taking_seizure_medications
    type: category.SEIZURE_BASELINE
    kind: MultipleChoice
    requirement:
      exists: true
    isBaseline: true
    choices:
      - common.yes
      - common.no

  - id: seizure-q4
    promptKey: seizure.q4.medication_names
    type: category.SEIZURE_BASELINE
    kind: FreeResponse
    isBaseline: true
    requirement:
      exists: true
    dependsOn:
      oneOf:
        - questionId: seizure-q3
          equals: 0

  - id: seizure-interim-q1
    promptKey: seizure.interim.q1.control_changed
    type: category.SEIZURE_INTERIM
    kind: MultipleChoice
    requirement:
      exists: true
    choices:
      - common.yes
      - common.no

  - id: seizure-interim-q2
    promptKey: seizure.interim.q2.increased
    type: category.SEIZURE_INTERIM
    kind: MultipleChoice
    requirement:
      exists: true
    choices:
      - common.yes
      - common.no
    dependsOn:
      oneOf:
        - questionId: seizure-interim-q1
          equals: 0

  - id: seizure-interim-q2a
    promptKey: seizure.interim.q2a.which_increased
    type: category.SEIZURE_INTERIM
    kind: AllThatApply
    requirement:
      exists: true
    choices: []
    fromBaseline: category.SEIZURE_BASELINE
    transform:
      type: mapChoices
      sourceId: seizure-q2
    dependsOn:
      oneOf:
        - questionId: seizure-interim-q2
          equals: 0

  - id: seizure-interim-q2b
    promptKey: seizure.interim.q2b.new_types
    type: category.SEIZURE_INTERIM
    kind: MultipleChoice
    requirement:
      exists: true
    choices:
      - common.yes
      - common.no
    dependsOn:
      oneOf:
        - questionId: seizure-interim-q2
          equals: 0

  - id: seizure-interim-q2c
    promptKey: seizure.interim.q2c.describe_new_types
    type: category.SEIZURE_INTERIM
    kind: FreeResponse
    requirement:
      exists: true
    dependsOn:
      oneOf:
        - questionId: seizure-interim-q2b
          equals: 0

  - id: seizure-interim-q3
    promptKey: seizure.interim.q3.sleep_quality_changed
    type: category.SEIZURE_INTERIM
    kind: MultipleChoice
    requirement:
      exists: true
    choices:
      - common.yes
      - common.no
    dependsOn:
      oneOf:
        - questionId: seizure-interim-q1
          equals: 0

  - id: seizure-interim-q3a
    promptKey: seizure.interim.q3a.describe_sleep_change
    type: category.SEIZURE_INTERIM
    kind: FreeResponse
    requirement:
      exists: true
    dependsOn:
      oneOf:
        - questionId: seizure-interim-q3
          equals: 0

  - id: seizure-interim-q4
    promptKey: seizure.interim.q4.medications_changed
    type: category.SEIZURE_INTERIM
    kind: MultipleChoice
    requirement:
      exists: true
    choices:
      - common.yes
      - common.no
    dependsOn:
      oneOf:
        - questionId: seizure-interim-q1
          equals: 0

  - id: seizure-interim-q5
    promptKey: seizure.interim.q5.list_medications
    type: category.SEIZURE_INTERIM
    kind: FreeResponse
    requirement:
      exists: true
    dependsOn:
      oneOf:
        - questionId: seizure-interim-q4
          equals: 0

recordPaths:
  - name: category.Meal-Time
    pages:
      - questionIds: [Meal-Type]

  - name: category.PAIN
    pages:
      - questionIds: [q14, q27, q28, q1, q18]
      - headerKey: pain.select_location
        questionIds: [Pain-Location]
        dependsOn:
          oneOf:
            - exists: q1
            - exists: q18
      - headerKey: pain.select_rating
        questionIds: [Pain-Rating]

  - name: category.BM
    pages:
      - headerKey: bm.select_type
        questionIds: [q4]
      - questionIds: [q3, q31, q30, q7, q8, q29, q9]
      - headerKey: bm.select_pain
        questionIds: [q6]
        dependsOn:
          oneOf:
            - exists: q8

  - name: category.REFLUX
    pages:
      - questionIds: [q20, q19, q10, q12, q11]

  - name: category.NB
    pages:
      - questionIds: [q21, q23, q22, q13, q2, q24, q25, q26]

  - name: category.SEIZURE_BASELINE
    isBaseline: true
    pages:
      - questionIds: [seizure-q1]
      - questionIds: [seizure-q2, seizure-q2-other]
        dependsOn:
          oneOf:
            - questionId: seizure-q1
              equals: 0
      - questionIds: [seizure-q3, seizure-q4]

  - name: category.SEIZURE_INTERIM
    period: w
    fromBaseline: category.SEIZURE_BASELINE
    pages:
      - questionIds: [seizure-interim-q1]
      - questionIds: [seizure-interim-q2, seizure-interim-q2a, seizure-interim-q2b, seizure-interim-q2c]
      - questionIds: [seizure-interim-q3, seizure-interim-q3a]
      - questionIds: [seizure-interim-q4, seizure-interim-q5]
''';

void main() {
  group('QuestionGraph & SessionGraph tests', () {
    test('QuestionGraphBuilder extracts edges correctly', () {
      const q1 = Check(id: 'q1', prompt: 'Question 1', type: 'c');
      final q2 = Check(
        id: 'q2',
        prompt: 'Question 2',
        type: 'c',
        dependsOn: DependsOn.fromString('(exact:q1:true)all'),
      );

      final home = _TestQuestionHome({'q1': q1, 'q2': q2});
      final path = RecordPath(
        name: 'test_path',
        pages: [
          PageLayout(questionIds: ['q1', 'q2']),
        ],
      );

      final graph = QuestionGraphBuilder.build(
        home: home,
        recordPaths: [path],
      );

      expect(graph.node('q1'), isNotNull);
      expect(graph.node('q2'), isNotNull);
      expect(graph.dependentsOf('q1'), contains('q2'));

      final nodeQ2 = graph.node('q2')!;
      expect(nodeQ2.edges, hasLength(1));
      expect(nodeQ2.edges.first.fromId, 'q1');
      expect(nodeQ2.edges.first.kind, EdgeKind.dependsOn);
    });

    test('SessionGraph evaluates page and question visibility reactively', () {
      const q1 = Check(id: 'q1', prompt: 'Question 1', type: 'c');
      final q2 = Check(
        id: 'q2',
        prompt: 'Question 2',
        type: 'c',
        dependsOn: DependsOn.fromString('(exists:q1)all'),
      );

      final home = _TestQuestionHome({'q1': q1, 'q2': q2});
      final path = RecordPath(
        name: 'test_path',
        pages: [
          PageLayout(questionIds: ['q1', 'q2']),
        ],
      );

      final graph = QuestionGraphBuilder.build(
        home: home,
        recordPaths: [path],
      );

      final session = graph.createSession(
        recordPathName: 'test_path',
      );

      final q2State = session.questionStateOf('q2')?.value;
      expect(q2State, isNotNull);
      expect(q2State!.visible, isFalse);

      session.setResponse(
        q1,
        response: Selected(question: q1, stamp: 100),
      );

      final q2Updated = session.questionStateOf('q2')?.value;
      expect(q2Updated!.visible, isTrue);

      expect(session.data.responses.containsKey('q1'), isTrue);

      session.dispose();
      graph.dispose();
    });

    test('SessionGraph resolves questions off baselineContext', () {
      const baseQ = AllThatApply(
        id: 'base_symptoms',
        prompt: 'Select baseline symptoms',
        type: 'symptom',
        choices: ['Nausea', 'Fatigue', 'Headache'],
      );

      final baselineResponse = DetailResponse(
        id: 'b:symptom:1',
        detailType: 'symptom',
        stamp: 1000,
        responses: [
          AllResponse(question: baseQ, responses: [0, 1], stamp: 1000),
        ],
      );

      final derivedQ = AllThatApply(
        id: 'derived_symptoms',
        prompt: 'Check current severity for baseline symptoms',
        type: 'symptom',
        fromBaseline: 'symptom',
        transform: '{"type":"mapChoices","sourceId":"base_symptoms"}',
        choices: const [],
      );

      final home = _TestQuestionHome({'derived_symptoms': derivedQ});
      final path = RecordPath(
        name: 'interim_path',
        pages: [
          PageLayout(questionIds: ['derived_symptoms']),
        ],
      );

      final graph = QuestionGraphBuilder.build(
        home: home,
        recordPaths: [path],
      );

      final session = graph.createSession(
        recordPathName: 'interim_path',
        baselines: [baselineResponse],
      );

      final derivedState = session.questionStateOf('derived_symptoms')?.value;
      expect(derivedState, isNotNull);
      final resolved = derivedState!.resolvedQuestion as AllThatApply;
      expect(resolved.choices, containsAll(['Nausea', 'Fatigue']));

      session.dispose();
      graph.dispose();
    });

    test('SessionGraph resolves generator questions using generateForEach transform', () {
      const seizureQ2 = AllThatApply(
        id: 'seizure-q2',
        prompt: 'seizure.q2.seizure_types',
        type: 'category.SEIZURE_BASELINE',
        isBaseline: true,
        transform:
            '{"type":"generateForEach","sourceId":"seizure-q2","generated":{"prompt":"seizure.q2.generated_frequency","type":"MultipleChoice","choices":["<1/mo","1/wk-1/mo",">1/day"]}}',
        choices: [
          'generalized_tonic_clonic',
          'absence_staring_spells',
          'drop_attacks_atonic',
          'focal',
          'other',
        ],
      );

      final baselineResponse = DetailResponse(
        id: 'b:seizure:1',
        detailType: 'category.SEIZURE_BASELINE',
        stamp: 1000,
        responses: [
          AllResponse(
            question: seizureQ2,
            responses: [0, 3],
            stamp: 1000,
          ),
        ],
      );

      const generatedQ = MultipleChoice(
        id: 'seizure-q2',
        prompt: 'seizure.q2.seizure_types',
        type: 'category.SEIZURE_BASELINE',
        fromBaseline: 'category.SEIZURE_BASELINE',
        transform:
            '{"type":"generateForEach","sourceId":"seizure-q2","generated":{"prompt":"seizure.q2.generated_frequency","type":"MultipleChoice","choices":["<1/mo","1/wk-1/mo",">1/day"]}}',
        choices: [],
      );

      final home = _TestQuestionHome({'seizure-q2': seizureQ2});
      final path = RecordPath(
        name: 'seizure_path',
        pages: [
          PageLayout(questionIds: ['seizure-q2']),
        ],
      );

      final graph = QuestionGraphBuilder.build(
        home: home,
        recordPaths: [path],
      );

      final session = graph.createSession(
        recordPathName: 'seizure_path',
        baselines: [baselineResponse],
      );

      final resolvedList = generatedQ.resolveFromBaseline(
        baseline: baselineResponse,
        baselineVersion: 1,
      );

      expect(resolvedList.length, equals(2));
      expect(
          resolvedList.first.id, equals('seizure-q2::generalizedtonicclonic::v1'));
      expect(resolvedList.last.id, equals('seizure-q2::focal::v1'));

      session.dispose();
      graph.dispose();
    });

    test('SessionGraph canSubmit computes session submission validity', () {
      final q1 = FreeResponse(
        id: 'q1',
        prompt: 'Required text',
        type: 'fr',
        requirement: Requirement.hasEntry(),
      );

      final home = _TestQuestionHome({'q1': q1});
      final path = RecordPath(
        name: 'submit_path',
        pages: [
          PageLayout(questionIds: ['q1']),
        ],
      );

      final graph = QuestionGraphBuilder.build(
        home: home,
        recordPaths: [path],
      );

      final session = graph.createSession(
        recordPathName: 'submit_path',
      );

      // Initially q1 is unanswered, so canSubmit is false
      expect(session.canSubmit, isFalse);

      // Add valid response for q1
      session.setResponse(
        q1,
        response: OpenResponse(question: q1, stamp: 100, response: 'Answered'),
      );

      // canSubmit should now be true
      expect(session.canSubmit, isTrue);

      session.dispose();
      graph.dispose();
    });

    test('SessionGraph enforces isRequired for every question kind', () {
      final questions = <Question>[
        const FreeResponse(
          id: 'free',
          prompt: 'Free',
          type: 'test',
          isRequired: true,
        ),
        const Numeric(
          id: 'numeric',
          prompt: 'Numeric',
          type: 'test',
          isRequired: true,
        ),
        const Check(
          id: 'check',
          prompt: 'Check',
          type: 'test',
          isRequired: true,
        ),
        const MultipleChoice(
          id: 'multiple',
          prompt: 'Multiple',
          type: 'test',
          choices: ['One'],
          isRequired: true,
        ),
        const AllThatApply(
          id: 'all',
          prompt: 'All',
          type: 'test',
          choices: ['One'],
          isRequired: true,
        ),
      ];
      final home = _TestQuestionHome({for (final q in questions) q.id: q});
      final path = RecordPath(
        name: 'required_path',
        pages: [PageLayout(questionIds: questions.map((q) => q.id).toList())],
      );
      final graph = QuestionGraphBuilder.build(
        home: home,
        recordPaths: [path],
      );
      final session = graph.createSession(recordPathName: path.name);

      expect(session.canSubmit, isFalse);
      expect(session.validatePage(0)?.pendingCount, questions.length);

      session.setResponse(
        questions[0],
        response: OpenResponse(
          question: questions[0] as FreeResponse,
          stamp: 1,
          response: 'answer',
        ),
      );

      expect(session.canSubmit, isFalse);
      expect(session.validatePage(0)?.pendingCount, questions.length - 1);

      session.dispose();
      graph.dispose();
    });

    test('SessionGraph validates every generated required question', () {
      final source = AllThatApply(
        id: 'source',
        prompt: 'Source',
        type: 'test',
        choices: const ['One', 'Two'],
        transform: '''{"type":"generateForEach","generated":{"prompt":"Generated {value}","type":"FreeResponse","isRequired":true}}''',
      );
      final home = _TestQuestionHome({'source': source});
      final path = RecordPath(
        name: 'generated_path',
        pages: [PageLayout(questionIds: const ['source'])],
      );
      final graph = QuestionGraphBuilder.build(
        home: home,
        recordPaths: [path],
      );
      final session = graph.createSession(recordPathName: path.name);

      session.setResponse(
        source,
        response: AllResponse(
          question: source,
          stamp: 1,
          responses: const [0, 1],
        ),
      );

      expect(session.canSubmit, isFalse);
      expect(session.validatePage(0)?.pendingCount, 1);

      for (final value in ['one', 'two']) {
        final generated = FreeResponse(
          id: 'source::$value',
          prompt: 'Generated $value',
          type: 'test',
          isRequired: true,
        );
        session.setResponse(
          generated,
          response: OpenResponse(
            question: generated,
            stamp: 1,
            response: 'answer',
          ),
        );
      }

      expect(session.canSubmit, isTrue);
      expect(session.validatePage(0)?.pendingCount, 0);

      session.dispose();
      graph.dispose();
    });

    test('Builds graph and evaluates sessions using production questions.yaml schema', () {
      final yamlData = loadYaml(_prodQuestionsYaml);
      final recordPaths = loadInRecordPaths(recordPathsYaml: yamlData['recordPaths']);

      final Set<String> baselineQuestionIds = {};
      for (final rp in recordPaths) {
        if (rp.isBaseline) {
          for (final page in rp.pages) {
            baselineQuestionIds.addAll(page.questionIds);
          }
        }
      }

      final questions = loadInQuestions(
        questionsYaml: yamlData['questions'],
        baselineIds: baselineQuestionIds,
      );

      final home = _TestQuestionHome(Map.fromEntries(questions.map((q) => MapEntry(q.id, q))));
      final graph = QuestionGraphBuilder.build(
        home: home,
        recordPaths: recordPaths,
      );

      // Verify Nodes exist
      expect(graph.node('seizure-q1'), isNotNull);
      expect(graph.node('seizure-q2'), isNotNull);
      expect(graph.node('seizure-interim-q1'), isNotNull);
      expect(graph.node('seizure-interim-q2a'), isNotNull);

      // 1. Create Baseline Session
      final baselineSession = graph.createSession(recordPathName: 'category.SEIZURE_BASELINE');
      expect(baselineSession.allPages.length, equals(3));
      expect(baselineSession.canSubmit, isFalse);

      // Answer seizure-q1 (had seizures = Yes)
      final seizureQ1 = home.all['seizure-q1'] as MultipleChoice;
      baselineSession.setResponse(
        seizureQ1,
        response: MultiResponse(question: seizureQ1, index: 0, stamp: 1000),
      );

      // Answer seizure-q2 (tonic-clonic [0] and focal [3])
      final seizureQ2 = home.all['seizure-q2'] as AllThatApply;
      baselineSession.setResponse(
        seizureQ2,
        response: AllResponse(question: seizureQ2, responses: [0, 3], stamp: 1000),
      );

      // Answer seizure-q3 (taking meds = No)
      final seizureQ3 = home.all['seizure-q3'] as MultipleChoice;
      baselineSession.setResponse(
        seizureQ3,
        response: MultiResponse(question: seizureQ3, index: 1, stamp: 1000),
      );

      for (final type in [
        'seizuretypegeneralizedtonicclonic',
        'seizuretypefocal',
      ]) {
        final generated = MultipleChoice(
          id: 'seizure-q2::$type',
          prompt: 'Frequency',
          type: 'category.SEIZURE_BASELINE',
          choices: const ['Less than monthly'],
          requirement: Requirement.hasEntry(),
        );
        baselineSession.setResponse(
          generated,
          response: MultiResponse(question: generated, index: 0, stamp: 1000),
        );
      }

      expect(baselineSession.canSubmit, isTrue);
      baselineSession.dumpDebugInfo();

      final baselineDetail = baselineSession.createDetailResponse(
        detailType: 'category.SEIZURE_BASELINE',
        id: 'b:category.SEIZURE_BASELINE:1',
      );

      // 2. Create Interim Session passing baselineDetail
      final interimSession = graph.createSession(
        recordPathName: 'category.SEIZURE_INTERIM',
        baselines: [baselineDetail],
      );

      // Verify seizure-interim-q2a dynamically populated choices from baseline choices 0 and 3
      final q2aState = interimSession.questionStateOf('seizure-interim-q2a')?.value;
      expect(q2aState, isNotNull);
      final resolvedQ2a = q2aState!.resolvedQuestion as AllThatApply;
      expect(
        resolvedQ2a.choices,
        containsAll([
          'seizure.type.generalized_tonic_clonic',
          'seizure.type.focal',
        ]),
      );

      interimSession.dispose();
      baselineSession.dispose();
      graph.dispose();
    });

    test('QuestionGraphBuilder autoCategorize automatically groups unassigned questions into record paths', () {
      const q1 = Check(id: 'q1', prompt: 'Pain 1', type: 'category.PAIN');
      const q2 = Check(id: 'q2', prompt: 'Custom 1', type: 'category.CUSTOM');
      const q3 = Check(id: 'q3', prompt: 'Custom 2', type: 'category.CUSTOM', isBaseline: true);

      final home = _TestQuestionHome({'q1': q1, 'q2': q2, 'q3': q3});

      // Pass NO record paths (empty list)
      final graph = QuestionGraphBuilder.build(
        home: home,
        recordPaths: [],
        autoCategorize: true,
      );

      // Verify RecordPaths were automatically generated for both categories
      final painPath = graph.recordPath('category.PAIN');
      expect(painPath, isNotNull);
      expect(painPath!.pages.first.questionIds, contains('q1'));

      final customPath = graph.recordPath('category.CUSTOM');
      expect(customPath, isNotNull);
      expect(customPath!.isBaseline, isTrue);
      expect(customPath.pages.first.questionIds, containsAll(['q2', 'q3']));

      graph.dispose();
    });
  });
}
