import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

class AppDateUtils {
  static String formatDate(DateTime date, {String? pattern}) {
    return DateFormat(pattern ?? AppConstants.dateFormatDate).format(date);
  }

  static String formatTime(DateTime time) {
    return DateFormat(AppConstants.dateFormatTime).format(time);
  }

  static String formatDateTime(DateTime dateTime) {
    return DateFormat(AppConstants.dateFormatFull).format(dateTime);
  }

  static DateTime? tryParse(String date, {String? pattern}) {
    try {
      return DateFormat(pattern ?? AppConstants.dateFormatDate).parse(date);
    } catch (e) {
      return null;
    }
  }

  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  AppDateUtils._();
} 