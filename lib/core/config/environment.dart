/// 环境配置
class Environment {
  /// 是否为开发环境
  static bool get isDevelopment {
    bool inDebugMode = false;
    assert(
      () {
        inDebugMode = true;
        return true;
      }(),
    );
    return inDebugMode;
  }

  /// 是否为生产环境
  static bool get isProduction => !isDevelopment;

  /// 数据库配置
  static const String databaseName = 'schedule_assistant.db';
  static const int databaseVersion = 103;

  /// 在开发环境中，每次启动时重新创建数据库
  static bool get shouldRecreateDatabase => isDevelopment;
} 