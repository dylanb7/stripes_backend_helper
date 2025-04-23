// ignore_for_file: constant_identifier_names
import 'package:rxdart/subjects.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/RepositoryBase/AuthBase/auth_user.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_repo_base.dart';

class TestQuestionRepo extends QuestionRepo {
  TestQuestionRepo({super.authUser = const AuthUser.empty()});

  @override
  BehaviorSubject<QuestionHome> get questions =>
      BehaviorSubject.seeded(QuestionHomeInst());

  @override
  Future<bool> addQuestion(Question question) {
    throw UnimplementedError();
  }

  @override
  Future<bool> removeQuestion(Question question) {
    throw UnimplementedError();
  }

  @override
  Future<bool> addRecordPath(String id, RecordPath path) {
    throw UnimplementedError();
  }

  @override
  Future<bool> removeRecordPath(String category) {
    // TODO: implement removeRecordPath
    throw UnimplementedError();
  }
}

const String q1 = '1';
const String q2 = '2';
const String q3 = '3';
const String q4 = '4';
const String q6 = '6';
const String q7 = '7';
const String q8 = '8';
const String q9 = '9';
const String q10 = '10';
const String q11 = '11';
const String q12 = '12';
const String q13 = '13';
const String q14 = '14';
const String q18 = '18';
const String q19 = '19';
const String q20 = '20';
const String q21 = '21';
const String q22 = '22';
const String q23 = '23';
const String q24 = '24';
const String q25 = '25';
const String q26 = '26';
const String q27 = '27';
const String q28 = '28';
const String q29 = '29';
const String q30 = '30';
const String q31 = '31';
const String q32 = '32';

const Map<String, String> questions = {
  q1: 'Pointed to stomach/tummy as if in pain',
  q2: 'Unable to sleep for an entire night',
  q3: 'Increased activity after BM',
  q4: 'Average BM type(1-7)',
  q6: 'Pain with BM',
  q7: 'Unable to reach the toilet in time',
  q8: 'Struggled or strained during BM',
  q9: 'Passed black or very dark, tar-like stool',
  q10: 'Rechewed, reswallowed, or spat out liquid or food from mouth or throat',
  q11: 'Vomited liquid or food from their stomach',
  q12: 'Attempted to vomit without producing any vomit',
  q13: 'Woke up too early and could not go back to sleep',
  q14: 'Tilted head to side and arched back',
  q18: 'Applied pressure to abdomen with hands or furniture',
  q19:
      'Choked, gagged, coughed or made sound (gurgling) with throat during or after swallowing meals',
  q20: 'Refused foods they once ate or had difficulty eating/swallowing',
  q21: 'Difficulty falling asleep',
  q22: 'Difficulty staying asleep',
  q23: 'Tossed and turned during sleep',
  q24: 'Increased irritability or grumpiness',
  q25: 'Aggressive behaviour towards others',
  q26: 'Showed Self-injury (e.g. head-banging, self-biting)',
  q27: 'Gritted teeth, winced, or grimaced as if in pain',
  q28: 'Moaned or made other noises as if in pain',
  q29: 'Lost control of urine or stool',
  q30: 'Experienced more gas or flatulence than usual',
  q31: "Swollen or bloated stomach",
  q32: "Verbalized that they're in pain"
};

class QuestionHomeInst extends QuestionHome {
  Map<String, List<Question>> types = {};
  QuestionHomeInst() {
    all.addAll({
      q1: Check(id: q1, prompt: questions[q1]!, type: Symptoms.PAIN),
      q2: Check(
        id: q2,
        prompt: questions[q2]!,
        type: Symptoms.NB,
      ),
      q3: Check(id: q3, prompt: questions[q3]!, type: Symptoms.BM),
      q4: Numeric(
          id: q4, prompt: questions[q4]!, type: Symptoms.BM, min: 1, max: 7),
      q6: Numeric(
          id: q6,
          prompt: questions[q6]!,
          type: Symptoms.BM,
          min: 0,
          max: 10,
          isRequired: true),
      q7: Check(id: q7, prompt: questions[q7]!, type: Symptoms.BM),
      q8: Check(id: q8, prompt: questions[q8]!, type: Symptoms.BM),
      q9: Check(id: q9, prompt: questions[q9]!, type: Symptoms.BM),
      q10: Check(
        id: q10,
        prompt: questions[q10]!,
        type: Symptoms.REFLUX,
      ),
      q11: Check(
        id: q11,
        prompt: questions[q11]!,
        type: Symptoms.REFLUX,
      ),
      q12: Check(
        id: q12,
        prompt: questions[q12]!,
        type: Symptoms.REFLUX,
      ),
      q13: Check(id: q13, prompt: questions[q13]!, type: Symptoms.NB),
      q14: Check(id: q14, prompt: questions[q14]!, type: Symptoms.PAIN),
      q18: Check(id: q18, prompt: questions[q18]!, type: Symptoms.PAIN),
      q19: Check(id: q19, prompt: questions[q19]!, type: Symptoms.REFLUX),
      q20: Check(id: q20, prompt: questions[q20]!, type: Symptoms.REFLUX),
      q21: Check(id: q21, prompt: questions[q21]!, type: Symptoms.NB),
      q22: Check(id: q22, prompt: questions[q22]!, type: Symptoms.NB),
      q23: Check(id: q23, prompt: questions[q23]!, type: Symptoms.NB),
      q24: Check(id: q24, prompt: questions[q24]!, type: Symptoms.NB),
      q25: Check(id: q25, prompt: questions[q25]!, type: Symptoms.NB),
      q26: Check(id: q26, prompt: questions[q26]!, type: Symptoms.NB),
      q27: Check(id: q27, prompt: questions[q27]!, type: Symptoms.PAIN),
      q28: Check(id: q28, prompt: questions[q28]!, type: Symptoms.PAIN),
      q29: Check(id: q29, prompt: questions[q29]!, type: Symptoms.BM),
      q30: Check(id: q30, prompt: questions[q30]!, type: Symptoms.BM),
      q31: Check(id: q31, prompt: questions[q31]!, type: Symptoms.BM),
      q32: Check(id: q32, prompt: questions[q32]!, type: Symptoms.PAIN)
    });
    for (final Question question in all.values) {
      if (types.containsKey(question.type)) {
        types[question.type]!.add(question);
      } else {
        types[question.type] = [question];
      }
    }
  }

  List<Question> get severityQuestions => [
        fromID(q1),
        fromID(q2),
        fromID(q6),
        fromID(q7),
        fromID(q8),
        fromID(q10),
        fromID(q11),
        fromID(q12),
        fromID(q13),
        fromID(q24),
        fromID(q25),
        fromID(q26),
      ];

  List<Question> get bm1 => [fromID(q4)];

  List<Question> get bm2 => [
        fromID(q6),
        fromID(q7),
        fromID(q8),
        fromID(q9),
      ];

  List<Question> get reflux => [
        fromID(q2),
        fromID(q10),
        fromID(q11),
        fromID(q12),
        fromID(q13),
        fromID(q19),
        fromID(q20)
      ];

  List<Question> get pain => [
        fromID(q1),
        fromID(q14),
        fromID(q18),
      ];

  List<Question> get nb => [
        fromID(q21),
        fromID(q22),
        fromID(q23),
        fromID(q24),
        fromID(q25),
        fromID(q26),
      ];

  @override
  Map<String, List<Question>> byType() => types;
}

class Symptoms {
  static const String BM = 'Bowel Movement';
  static const String PAIN = 'Pain';
  static const String REFLUX = 'GI Symptoms';
  static const String NB = 'Sleep & Mood';

  static List<String> ordered() => [BM, PAIN, REFLUX, NB];
}
