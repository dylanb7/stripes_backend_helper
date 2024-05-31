// ignore_for_file: constant_identifier_names
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/RepositoryBase/AuthBase/auth_user.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_repo_base.dart';

class TestQuestionRepo extends QuestionRepo {
  TestQuestionRepo({super.authUser = const AuthUser.empty()});

  @override
  QuestionHome get questions => QuestionHomeInst();
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

const Map<String, String> questions = {
  q1: 'Pointing to stomach/tummy as if in pain',
  q2: 'Nausea',
  q3: 'Become more active after passing a stool?',
  q4: 'Average BM type(1-7)',
  q6: 'Pain with BM',
  q7: 'Rush to the bathroom for BM',
  q8: 'Straining with BM',
  q9: 'Black tarry BM',
  q10: 'Spit up',
  q11: 'Regurgitated',
  q12: 'Experienced retching',
  q13: 'Vomiting',
  q14: 'Tilted head to side and arched back',
  q18: 'Applied pressure to abdomen with hands or furniture',
  q19:
      'Choked, gagged coughed or made sound (gurgling) with throat during or after swallowing or meals',
  q20: 'Refused foods they once ate',
  q21: 'Insomnia (difficulty falling asleep at beginning of night)',
  q22: 'Awakenings',
  q23: 'Restless sleep',
  q24: 'Irritability',
  q25: 'Aggressive/violent behaviors towards others',
  q26: 'Self injurious behaviors',
  q27: 'Gritting teeth, wincing, or grimacing for no obvious reason',
  q28: 'Moaning or groaning for no apparent reason',
  q29: 'Incontinence / Lack of voluntary control over urination or defecation',
  q30: 'Flatulence or Gas',
};

class QuestionHomeInst extends QuestionHome {
  QuestionHomeInst() {
    all.addAll({
      q1: Check(id: q1, prompt: questions[q1]!, type: Symptoms.PAIN),
      q2: Numeric(
          id: q2,
          prompt: questions[q2]!,
          type: Symptoms.REFLUX,
          min: 1,
          max: 5),
      q3: Check(id: q3, prompt: questions[q3]!, type: Symptoms.BM),
      q4: Numeric(
          id: q4, prompt: questions[q4]!, type: Symptoms.BM, min: 1, max: 7),
      q6: Numeric(
          id: q6, prompt: questions[q6]!, type: Symptoms.BM, min: 0, max: 10),
      q7: Check(id: q7, prompt: questions[q7]!, type: Symptoms.BM),
      q8: Check(id: q8, prompt: questions[q8]!, type: Symptoms.BM),
      q9: Check(id: q9, prompt: questions[q9]!, type: Symptoms.BM),
      q10: Check(
        id: q10,
        prompt: questions[q10]!,
        type: Symptoms.REFLUX,
      ),
      q11: Numeric(
          id: q11,
          prompt: questions[q11]!,
          type: Symptoms.REFLUX,
          min: 1,
          max: 5),
      q12: Check(
        id: q12,
        prompt: questions[q12]!,
        type: Symptoms.REFLUX,
      ),
      q13: Numeric(
          id: q13,
          prompt: questions[q13]!,
          type: Symptoms.REFLUX,
          min: 1,
          max: 5),
      q14: Check(id: q14, prompt: questions[q14]!, type: Symptoms.PAIN),
      q18: Check(id: q18, prompt: questions[q18]!, type: Symptoms.PAIN),
      q19: Check(id: q19, prompt: questions[q19]!, type: Symptoms.REFLUX),
      q20: Check(id: q20, prompt: questions[q20]!, type: Symptoms.REFLUX),
      q21: Check(id: q21, prompt: questions[q21]!, type: Symptoms.NB),
      q22: Check(id: q22, prompt: questions[q22]!, type: Symptoms.NB),
      q23: Check(id: q23, prompt: questions[q23]!, type: Symptoms.NB),
      q24: Numeric(
          id: q24, prompt: questions[q24]!, type: Symptoms.NB, min: 1, max: 5),
      q25: Numeric(
          id: q25, prompt: questions[q25]!, type: Symptoms.NB, min: 1, max: 5),
      q26: Numeric(
          id: q26, prompt: questions[q26]!, type: Symptoms.NB, min: 1, max: 5),
      q27: Check(id: q27, prompt: questions[q27]!, type: Symptoms.PAIN),
      q28: Check(id: q28, prompt: questions[q28]!, type: Symptoms.PAIN),
      q29: Check(id: q29, prompt: questions[q29]!, type: Symptoms.BM),
      q30: Check(id: q30, prompt: questions[q30]!, type: Symptoms.BM),
    });
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
}

class Symptoms {
  static const String BM = 'Bowel Movement';
  static const String PAIN = 'Pain';
  static const String REFLUX = 'Reflux';
  static const String NB = 'Neurological Behavior';

  static List<String> ordered() => [BM, PAIN, REFLUX, NB];
}
