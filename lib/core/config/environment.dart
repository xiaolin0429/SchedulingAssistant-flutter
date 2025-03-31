import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  /// 数据库版本号
  /// 当数据库表结构发生变化时，需要更新此版本号
  static const int databaseVersion = 103;

  /// 数据库表结构哈希值
  /// 仅在开发环境下使用，用于检测表结构变化
  /// 当修改了表结构（包括表名、字段、索引等）时，需要更新此值
  static const String _devDatabaseSchemaHash = '20240219_v1';

  /// 获取存储的schema哈希值的key
  static const String _schemaHashKey = 'database_schema_hash';

  /// 数据库是否需要重新创建
  /// 仅在开发环境下，且数据库表结构发生变化时返回true
  static Future<bool> get shouldRecreateDatabase async {
    if (!isDevelopment) return false;

    try {
      final prefs = await SharedPreferences.getInstance();
      final storedHash = prefs.getString(_schemaHashKey);

      // 如果存储的哈希值与当前不一致，说明表结构已变化
      if (storedHash != _devDatabaseSchemaHash) {
        // 更新存储的哈希值
        await prefs.setString(_schemaHashKey, _devDatabaseSchemaHash);
        debugPrint('检测到数据库表结构变化，将重新创建数据库');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('检查数据库schema失败: $e');
      return false;
    }
  }
}
