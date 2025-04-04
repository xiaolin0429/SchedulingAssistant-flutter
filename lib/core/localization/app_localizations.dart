import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  // 静态成员，用于在整个应用中访问本地化实例
  static AppLocalizations of(BuildContext context) {
    final localizations =
        Localizations.of<AppLocalizations>(context, AppLocalizations);
    if (localizations == null) {
      debugPrint(
          '警告: AppLocalizations未初始化，请确保在MaterialApp中添加了AppLocalizations.delegate');
      debugPrint(
          '当前context: ${context.widget.runtimeType}, 当前locale: ${Localizations.localeOf(context)}');
      // 返回一个带有空Map的实例，避免空指针异常
      final fallback = AppLocalizations(const Locale('zh'));
      fallback._localizedStrings = {};
      return fallback;
    }
    return localizations;
  }

  // 委托类，用于加载本地化资源
  static final LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  // 存储翻译文本的Map
  late Map<String, String> _localizedStrings;

  // 加载本地化文件
  Future<bool> load() async {
    try {
      // 加载语言JSON文件
      debugPrint('开始加载本地化文件: assets/i18n/${locale.languageCode}.json');
      debugPrint('当前区域设置: ${locale.toString()}');

      String jsonString;
      try {
        jsonString = await rootBundle
            .loadString('assets/i18n/${locale.languageCode}.json');
        debugPrint(
            '成功加载语言文件: ${locale.languageCode}.json，长度: ${jsonString.length}');
      } catch (e) {
        debugPrint('加载${locale.languageCode}.json失败，回退到中文: $e');
        // 如果加载失败，回退到中文
        jsonString = await rootBundle.loadString('assets/i18n/zh.json');
        debugPrint('已回退到中文文件，长度: ${jsonString.length}');
      }

      Map<String, dynamic> jsonMap = json.decode(jsonString);
      debugPrint('JSON解析成功，键值对数量: ${jsonMap.length}');

      _localizedStrings = jsonMap.map((key, value) {
        return MapEntry(key, value.toString());
      });

      debugPrint('本地化字符串初始化完成，示例: ${_localizedStrings['app_title']}');
      return true;
    } catch (e) {
      debugPrint('本地化过程发生错误: $e');
      _localizedStrings = {};
      return false;
    }
  }

  // 获取翻译文本
  String translate(String key) {
    if (_localizedStrings.isEmpty) {
      debugPrint('警告: 本地化字符串为空，key: $key');
      return key;
    }
    final value = _localizedStrings[key];
    if (value == null) {
      debugPrint(
          '警告: 未找到本地化字符串，key: $key, 可用keys: ${_localizedStrings.keys.take(5).join(", ")}...');
      return key;
    }
    return value;
  }
}

// 本地化委托类
class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  // 使用工厂构造函数，确保单例
  static final _AppLocalizationsDelegate _instance =
      _AppLocalizationsDelegate._internal();

  factory _AppLocalizationsDelegate() {
    return _instance;
  }

  _AppLocalizationsDelegate._internal();

  // 支持的语言列表
  @override
  bool isSupported(Locale locale) {
    return ['en', 'zh'].contains(locale.languageCode);
  }

  // 加载本地化资源
  @override
  Future<AppLocalizations> load(Locale locale) async {
    debugPrint('开始加载本地化资源，locale: ${locale.languageCode}');
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load();
    debugPrint('本地化资源加载完成，locale: ${locale.languageCode}');
    return localizations;
  }

  // 是否需要重新加载
  @override
  bool shouldReload(_AppLocalizationsDelegate old) => true;
}
