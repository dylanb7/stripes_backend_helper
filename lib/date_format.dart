int dateToStamp(DateTime date) => date.millisecondsSinceEpoch;
DateTime dateFromStamp(int stamp) => DateTime.fromMillisecondsSinceEpoch(stamp);
