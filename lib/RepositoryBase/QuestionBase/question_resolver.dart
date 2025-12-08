import 'dart:convert';

import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/QuestionModel/response.dart';

enum TransformType {
  mapChoices('mapChoices'),
  copyValue('copyValue');

  final String id;
  const TransformType(this.id);

  static TransformType? fromId(String? id) {
    if (id == null) return null;
    return TransformType.values.cast<TransformType?>().firstWhere(
          (t) => t!.id == id,
          orElse: () => null,
        );
  }
}

extension QuestionResolver on Question {
  Question resolve(Response baseline) {
    if (fromBaseline == null || transform == null) return this;

    try {
      final Map<String, dynamic> transformData = jsonDecode(transform!);
      final String? targetId = transformData['sourceId'];
      final TransformType? type = TransformType.fromId(transformData['type']);

      if (targetId == null || type == null) return this;

      List<Response> targetResponses = [];

      if (baseline is ResponseWrap) {
        targetResponses =
            baseline.responses.where((r) => r.question.id == targetId).toList();
      } else {
        if (baseline.question.id == targetId) {
          targetResponses = [baseline];
        }
      }

      if (targetResponses.isEmpty) return this;

      switch (type) {
        case TransformType.mapChoices:
          if (this is MultipleChoice) {
            List<String> newChoices = [];
            for (final targetResponse in targetResponses) {
              if (targetResponse is OpenResponse) {
                newChoices.add(targetResponse.response);
              } else if (targetResponse is MultiResponse) {
                newChoices.add(targetResponse.choice);
              } else if (targetResponse is AllResponse) {
                newChoices.addAll(targetResponse.choices);
              }
            }
            return (this as MultipleChoice).copyWith(choices: newChoices);
          }
          break;
        case TransformType.copyValue:
          final firstResponse = targetResponses.first;
          String valueToCopy = "";
          switch (firstResponse) {
            case OpenResponse(response: final response):
              valueToCopy = response;
              break;
            case MultiResponse(index: final index, question: final question):
              valueToCopy = question.choices[index];
              break;
            case NumericResponse(response: final response):
              valueToCopy = response.toString();
              break;
            default:
              break;
          }

          final newPrompt =
              prompt.replaceAll(RegExp(r'\[value\]'), valueToCopy);
          switch (this) {
            case FreeResponse():
              return (this as FreeResponse).copyWith(prompt: newPrompt);
            case Numeric():
              return (this as Numeric).copyWith(prompt: newPrompt);
            case Check():
              return (this as Check).copyWith(prompt: newPrompt);
            case MultipleChoice():
              return (this as MultipleChoice).copyWith(prompt: newPrompt);
            case AllThatApply():
              return (this as AllThatApply).copyWith(prompt: newPrompt);
          }
      }

      return this;
    } catch (e) {
      return this;
    }
  }
}
