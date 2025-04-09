import 'package:flutter/services.dart';

/// 法律文档加载工具类
class LegalDocumentLoader {
  /// 隐私政策文件路径
  static const String privacyPolicyPath = 'assets/legal/privacy_policy.md';

  /// 用户协议文件路径
  static const String userAgreementPath = 'assets/legal/user_agreement.md';

  /// 加载隐私政策文档
  static Future<String> loadPrivacyPolicy() async {
    try {
      return await rootBundle.loadString(privacyPolicyPath);
    } catch (e) {
      return '无法加载隐私政策文档：$e';
    }
  }

  /// 加载用户协议文档
  static Future<String> loadUserAgreement() async {
    try {
      return await rootBundle.loadString(userAgreementPath);
    } catch (e) {
      return '无法加载用户协议文档：$e';
    }
  }
}
