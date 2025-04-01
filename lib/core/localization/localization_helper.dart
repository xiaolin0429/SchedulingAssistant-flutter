import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 本地化帮助类，提供常用的本地化功能
class LocalizationHelper {
  /// 获取本地化的日期格式
  static String formatDate(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMd(locale).format(date);
  }

  /// 获取本地化的时间格式
  static String formatTime(BuildContext context, DateTime time) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.Hm(locale).format(time);
  }

  /// 获取本地化的日期时间格式
  static String formatDateTime(BuildContext context, DateTime dateTime) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMd(locale).add_Hm().format(dateTime);
  }

  /// 获取本地化的数字格式
  static String formatNumber(BuildContext context, num number) {
    final locale = Localizations.localeOf(context).toString();
    return NumberFormat.decimalPattern(locale).format(number);
  }

  /// 获取本地化的货币格式
  static String formatCurrency(BuildContext context, num amount) {
    final locale = Localizations.localeOf(context).toString();
    return NumberFormat.currency(locale: locale, symbol: '¥').format(amount);
  }

  /// 获取本地化的百分比格式
  static String formatPercent(BuildContext context, num percent) {
    final locale = Localizations.localeOf(context).toString();
    return NumberFormat.percentPattern(locale).format(percent / 100);
  }

  /// 获取当前语言代码
  static String getCurrentLanguage(BuildContext context) {
    return Localizations.localeOf(context).languageCode;
  }

  /// 判断是否为中文环境
  static bool isChinese(BuildContext context) {
    return getCurrentLanguage(context) == 'zh';
  }

  /// 判断是否为英文环境
  static bool isEnglish(BuildContext context) {
    return getCurrentLanguage(context) == 'en';
  }
} 