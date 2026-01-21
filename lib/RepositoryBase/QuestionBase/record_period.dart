import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum Period {
  day,
  week,
  month,
  year;

  String toId() {
    switch (this) {
      case Period.day:
        return "d";
      case Period.week:
        return "w";
      case Period.month:
        return "m";
      case Period.year:
        return "y";
    }
  }

  static Period fromId(String id) {
    if (id == "d") return Period.day;
    if (id == "w") return Period.week;
    if (id == "m") return Period.month;
    return Period.year;
  }

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
        final DateTime end = DateTime(start.year, start.month, start.day + 1);
        return DateTimeRange(start: start, end: end);
      case Period.week:
        final DateTime end = DateTime(start.year, start.month, start.day + 7);
        return DateTimeRange(start: start, end: end);
      case Period.month:
        final DateTime end = DateTime(start.year, start.month + 1, start.day);
        return DateTimeRange(start: start, end: end);
      case Period.year:
        final DateTime end = DateTime(start.year + 1, start.month, start.day);
        return DateTimeRange(start: start, end: end);
    }
  }

  String getRangeString(DateTime time, BuildContext context) {
    DateTimeRange range = getRange(time);
    String locale = Localizations.localeOf(context).languageCode;

    final DateFormat yearFormat = DateFormat.yMMMd(locale);

    switch (this) {
      case Period.day:
        return yearFormat.format(range.start);
      case Period.week:
        final bool sameYear = range.end.year == range.start.year;
        final bool sameMonth = sameYear && range.end.month == range.start.month;
        final String firstPortion = sameYear
            ? DateFormat.MMMd(locale).format(range.start)
            : yearFormat.format(range.start);
        final String lastPortion = sameMonth
            ? '${DateFormat.d(locale).format(range.end)}, ${DateFormat.y(locale).format(range.end)}'
            : yearFormat.format(range.end);
        return '$firstPortion - $lastPortion';
      case Period.month:
        return DateFormat.yMMM(locale).format(range.start);
      case Period.year:
        return DateFormat.y(locale).format(range.start);
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
    // Use calendar arithmetic instead of Duration to handle DST correctly
    final int daysToSubtract = (date.weekday - day) % DateTime.daysPerWeek;
    return DateTime(date.year, date.month, date.day - daysToSubtract);
  }
}
