import 'package:flutter/material.dart';
import 'app_localizations.dart';

/// 本地化文本组件，用于在UI中显示翻译后的文本
class AppText extends StatelessWidget {
  final String textKey;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final String? fallbackText;
  
  const AppText(
    this.textKey, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.fallbackText,
  });
  
  @override
  Widget build(BuildContext context) {
    final translatedText = AppLocalizations.of(context).translate(textKey);
    final displayText = translatedText == textKey && fallbackText != null ? fallbackText! : translatedText;
    
    return Text(
      displayText,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// 扩展String类，添加本地化方法
extension LocalizedString on String {
  /// 获取本地化文本
  String tr(BuildContext context) {
    return AppLocalizations.of(context).translate(this);
  }
  
  /// 获取本地化文本，带备选文本
  String trOr(BuildContext context, String fallback) {
    final translated = AppLocalizations.of(context).translate(this);
    return translated == this ? fallback : translated;
  }
} 