import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/transform.dart';

export 'transform.dart';

extension QuestionResolver on Question {
  List<Question> resolve({required Response current}) {
    if (transform == null) return [this];
    return _resolveInternal(source: current, allowSelfSource: true);
  }

  List<Question> resolveFromBaseline({
    required Response baseline,
    int? baselineVersion,
  }) {
    if (transform == null || fromBaseline == null) return [this];
    return _resolveInternal(
      source: baseline,
      baselineVersion: baselineVersion,
      allowSelfSource: false,
    );
  }

  List<Question> _resolveInternal({
    required Response source,
    int? baselineVersion,
    bool allowSelfSource = false,
  }) {
    final Transform? xform = Transform.parse(transform);
    if (xform == null) return [this];

    List<Response> sourceResponses;
    if (xform.sourceId == null) {
      if (!allowSelfSource) return [this];
      sourceResponses = getSourceResponses(source, null, id);
    } else {
      sourceResponses = getSourceResponses(source, xform.sourceId, id);
    }

    if (sourceResponses.isEmpty) return [this];

    return xform.apply(this, sourceResponses, baselineVersion: baselineVersion);
  }
}
