import 'package:flutter/material.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_backend_helper/RepositoryBase/AuthBase/auth_user.dart';

abstract class QuestionRepo<T extends QuestionHome> {
  final AuthUser authUser;

  QuestionRepo({required this.authUser});

  Map<String, RecordPath> getLayouts() => {};

  T get questions;
}

@immutable
class RecordPath {
  final List<PageLayout> pages;
  final Period? period;
  const RecordPath({required this.pages, this.period});
}

@immutable
class PageLayout {
  final List<Question> questions;

  final String? header;

  const PageLayout({required this.questions, this.header});
}

abstract class QuestionHome {
  Map<String, Question> all = {};

  Question fromID(String id) => all[id] ?? Question.empty();
}

enum Period {
  day,
  week,
  month,
  year;

  DateTime getValue(DateTime entry) {
    switch (this) {
      case Period.day:
        return DateTime(entry.year, entry.month, entry.day);
      case Period.week:
        final DateTime prev = previous(entry, DateTime.monday);
        return DateTime(prev.year, prev.month, prev.day);
      case Period.month:
        return DateTime(entry.year, entry.month);
      case Period.year:
        return DateTime(entry.year);
    }
  }

  DateTimeRange getRange(DateTime entry) {
    final DateTime start = getValue(entry);
    switch (this) {
      case Period.day:
        final DateTime end = start.add(const Duration(days: 1));
        return DateTimeRange(start: start, end: end);
      case Period.week:
        final DateTime end = start.add(const Duration(days: 7));
        return DateTimeRange(start: start, end: end);
      case Period.month:
        final DateTime end = start.add(Duration(days: daysInMonth(entry)));
        return DateTimeRange(start: start, end: end);
      case Period.year:
        final DateTime end = start.add(const Duration(days: 365));
        return DateTimeRange(start: start, end: end);
    }
  }

  const Period();
}

int daysInMonth(DateTime date) {
  DateTime firstOfNextMonth;
  if (date.month == 12) {
    firstOfNextMonth = DateTime(date.year + 1, 1, 1, 12);
  } else {
    firstOfNextMonth = DateTime(date.year, date.month + 1, 1, 12);
  }
  return firstOfNextMonth.subtract(const Duration(days: 1)).day;
}

DateTime previous(DateTime date, int day) {
  if (day == date.weekday) {
    return date;
  } else {
    return date.subtract(
      Duration(
        days: (date.weekday - day) % DateTime.daysPerWeek,
      ),
    );
  }
}
