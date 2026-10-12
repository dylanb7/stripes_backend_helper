import 'dart:convert';

import 'package:stripes_backend_helper/QuestionModel/response.dart';
import 'package:stripes_backend_helper/RepositoryBase/EntryBase/entry.dart';
import 'package:stripes_backend_helper/RepositoryBase/QuestionBase/question_repo_base.dart';
import 'package:stripes_backend_helper/RepositoryBase/TestBase/BlueDye/blue_dye_impl.dart';
import 'package:stripes_backend_helper/RepositoryBase/TestBase/BlueDye/blue_dye_response.dart';
import 'package:stripes_backend_helper/RepositoryBase/TestBase/BlueDye/bm_test_log.dart';
import 'package:stripes_backend_helper/date_format.dart';
import 'package:stripes_backend_helper/db_keys.dart';

Map<String, dynamic> detailResponseToEntryData(DetailResponse resp) {
  return {
    DESCRIPTION_FIELD: resp.description,
    'responses': resp.responses.map(responseItemToJson).toList(),
  };
}

Entry detailResponseToEntry(
  DetailResponse resp,
  String subUserId, {
  InputCategory category = InputCategory.event,
  String? sessionId,
  bool? isBlue,
}) {
  final entryData = detailResponseToEntryData(resp);
  entryData['type'] = resp.type;
  if (isBlue != null) {
    entryData['isBlue'] = isBlue;
  }

  return Entry(
    id: resp.id,
    subUserId: subUserId,
    group: resp.group,
    stamp: dateFromStamp(resp.stamp),
    entityType: category.name,
    data: entryData,
    sessionId: sessionId ?? resp.linkingId,
  );
}

DetailResponse entryToDetailResponse(Entry entry, QuestionHome home) {
  final Map<String, dynamic> data = entry.data;
  final String? desc = data[DESCRIPTION_FIELD] as String?;
  final List<dynamic> responsesRaw = data['responses'] as List<dynamic>? ?? [];
  final int parentStamp = entry.stamp.millisecondsSinceEpoch;

  final List<Response> responses = responsesRaw.map((item) {
    final Map<String, dynamic> map = Map<String, dynamic>.from(item as Map);
    return responseItemFromJson(map, home, parentStamp, entry.group);
  }).toList();

  return DetailResponse(
    id: entry.id,
    group: entry.group,
    linkingId: entry.sessionId,
    stamp: parentStamp,
    responses: responses,
    description: desc,
    detailType: data['type'] as String? ?? entry.entityType,
  );
}

extension DetailResponseEntryExtension on DetailResponse {
  Entry toEntry(
    String subUserId, {
    InputCategory category = InputCategory.event,
    String? sessionId,
    bool? isBlue,
  }) => detailResponseToEntry(
    this,
    subUserId,
    category: category,
    sessionId: sessionId,
    isBlue: isBlue,
  );
}

extension EntryDetailResponseExtension on Entry {
  DetailResponse toDetailResponse(QuestionHome home) =>
      entryToDetailResponse(this, home);
}

Entry blueDyeTestToEntry(
  BlueDyeState state,
  String subUserId, {
  String? sessionId,
}) {
  return Entry(
    id: state.id,
    subUserId: subUserId,
    stamp: state.startTime ?? DateTime.now(),
    entityType: InputCategory.test.name,
    data: {
      'type': 'blue_dye_test',
      if (state.finishedEating != null)
        FINISHED_KEY: state.finishedEating!.inMilliseconds,
      if (state.finishedEatingTime != null)
        FINISHED_TIME_KEY: dateToStamp(state.finishedEatingTime!),
      if (state.timerStart != null) TIMER_START: dateToStamp(state.timerStart!),
      if (state.pauseTime != null) PAUSE_TIME: dateToStamp(state.pauseTime!),
      if (state.amountConsumed != null)
        AMOUNT_CONSUMED: state.amountConsumed.toString(),
    },
    sessionId: sessionId,
  );
}

BlueDyeState entryToBlueDyeState(Entry entry) {
  final Map<String, dynamic> d = entry.data;
  return BlueDyeState(
    id: entry.id,
    startTime: entry.stamp,
    finishedEating: toDuration(d[FINISHED_KEY] as int?),
    finishedEatingTime: d.containsKey(FINISHED_TIME_KEY)
        ? dateFromStamp(d[FINISHED_TIME_KEY] as int)
        : null,
    timerStart: d.containsKey(TIMER_START)
        ? dateFromStamp(d[TIMER_START] as int)
        : null,
    pauseTime: d.containsKey(PAUSE_TIME)
        ? dateFromStamp(d[PAUSE_TIME] as int)
        : null,
    amountConsumed: parseAmountConsumed(d[AMOUNT_CONSUMED] as String?),
    logs: [],
  );
}

Entry bmTestLogToEntry(BMTestLog log, String subUserId, String sessionId) {
  return detailResponseToEntry(
    log.response,
    subUserId,
    sessionId: sessionId,
    isBlue: log.isBlue,
  );
}

BMTestLog entryToBMTestLog(Entry entry, QuestionHome home) {
  final bool isBlue = entry.data['isBlue'] as bool? ?? false;
  return BMTestLog(
    id: entry.id,
    isBlue: isBlue,
    response: entryToDetailResponse(entry, home),
  );
}

BlueDyeResp sessionToBlueDyeResp(
  Entry testEntry,
  List<Entry> logEntries,
  QuestionHome home,
) {
  final Map<String, dynamic> d = testEntry.data;
  final int durationMs = d[FINISHED_KEY] as int? ?? 0;

  final List<BMTestLog> logs =
      logEntries.map((e) => entryToBMTestLog(e, home)).toList()
        ..sort((a, b) => a.stamp.compareTo(b.stamp));

  final blueLogs = logs.where((l) => l.isBlue).toList();

  return BlueDyeResp(
    id: testEntry.id,
    group: testEntry.group,
    startEating: testEntry.stamp,
    eatingDuration: Duration(milliseconds: durationMs),
    finishedEatingTime: d.containsKey(FINISHED_TIME_KEY)
        ? dateFromStamp(d[FINISHED_TIME_KEY] as int)
        : null,
    normalBowelMovements: logs.length - blueLogs.length,
    blueBowelMovements: blueLogs.length,
    firstBlue: blueLogs.isNotEmpty
        ? dateFromStamp(blueLogs.first.stamp)
        : testEntry.stamp,
    lastBlue: blueLogs.isNotEmpty
        ? dateFromStamp(blueLogs.last.stamp)
        : testEntry.stamp,
    logs: logs,
    amountConsumed:
        parseAmountConsumed(d[AMOUNT_CONSUMED] as String?) ??
        AmountConsumed.undetermined,
  );
}

Map<String, dynamic> responseItemToJson(Response response) {
  if (response is UnresolvedResponse) return response.raw;
  final Map<String, dynamic> json = {
    ID_FIELD: response.isGeneratedQuestion
        ? jsonEncode(response.question.toJson())
        : response.question.id,
    STAMP_ID: response.id,
  };

  switch (response) {
    case OpenResponse r:
      json[RESPONSE_FIELD] = r.response;
    case NumericResponse r:
      json[NUMERIC_RESPONSE_FIELD] = r.response;
    case MultiResponse r:
      json[SELECTED_FIELD] = r.index;
    case AllResponse r:
      json[SELECTED_FIELDS] = r.responses;
    case Selected _:
      break;
    default:
      break;
  }
  return json;
}

Response responseItemFromJson(
  Map<String, dynamic> map,
  QuestionHome home,
  int parentStamp,
  String? group,
) {
  return decodeResponseItem(map, home, parentStamp, group);
}
