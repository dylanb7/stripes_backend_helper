import 'package:flutter/material.dart';

String dateToMDY(DateTime dateTime) {
  return '${_elongate(dateTime.month.toString())}/${_elongate(dateTime.day.toString())}/${dateTime.year}';
}

String dateToMDYAbr(DateTime dateTime) {
  final String yearStr = dateTime.year.toString().substring(2);
  return '${dateTime.month}/${dateTime.day}/$yearStr';
}

const List<String> monthsShort = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec'
];
String dateToShortMDY(DateTime dateTime) {
  return '${monthsShort[dateTime.month - 1]} ${_elongate(dateTime.day.toString())} ${dateTime.year}';
}

String timeString(TimeOfDay time, {bool hasPeriod = true}) {
  final String base =
      '${time.hourOfPeriod}:${_elongate(time.minute.toString())}';
  return hasPeriod ? '$base ${time.period.name.toUpperCase()}' : base;
}

String _elongate(String unit) {
  return unit.length == 1 ? '0$unit' : unit;
}

extension DateTimeExtension on DateTime {
  String getDayString() {
    switch (weekday) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return 'Err';
    }
  }

  String getMonthString() {
    switch (month) {
      case 1:
        return 'January';
      case 2:
        return 'Febuary';
      case 3:
        return 'March';
      case 4:
        return 'April';
      case 5:
        return 'May';
      case 6:
        return 'June';
      case 7:
        return 'July';
      case 8:
        return 'August';
      case 9:
        return 'September';
      case 10:
        return 'October';
      case 11:
        return 'November';
      case 12:
        return 'December';
      default:
        return 'Err';
    }
  }
}

int dateToStamp(DateTime date) => date.millisecondsSinceEpoch;
DateTime dateFromStamp(int stamp) => DateTime.fromMillisecondsSinceEpoch(stamp);
