import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

/// 日志级别
enum LogLevel {
  verbose,
  debug,
  info,
  warning,
  error,
  none,
}

/// 日志服务类
class LogService {
  static final LogService _instance = LogService._internal();

  /// 单例模式构造函数
  factory LogService() => _instance;

  /// 内部构造函数
  LogService._internal();

  /// 当前日志级别，低于此级别的日志将不会被记录
  LogLevel _currentLevel = LogLevel.debug;

  /// 是否将日志写入文件
  bool _writeToFile = true;

  /// 日志文件缓冲区
  final List<String> _logBuffer = [];

  /// 日志文件最大大小（字节）
  static const int _maxLogFileSize = 5 * 1024 * 1024; // 5MB

  /// 日志文件最大行数
  static const int _maxBufferLines = 500;

  /// 日志文件路径
  String? _logFilePath;

  /// 设置当前日志级别
  void setLogLevel(LogLevel level) {
    _currentLevel = level;
  }

  /// 设置是否将日志写入文件
  void setWriteToFile(bool value) {
    _writeToFile = value;
  }

  /// 初始化日志服务
  Future<void> initialize() async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final logDir = Directory('${appDocDir.path}/logs');

      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }

      final now = DateTime.now();
      final formatter = DateFormat('yyyy-MM-dd');
      _logFilePath = '${logDir.path}/app_logs_${formatter.format(now)}.txt';

      // 检查日志文件是否存在
      final logFile = File(_logFilePath!);
      if (!await logFile.exists()) {
        await logFile.create();

        // 写入日志文件头部信息
        final header = '''
日志生成时间: ${DateTime.now()}
应用版本: 1.0.0
----------------------------
''';
        await logFile.writeAsString(header);
      }

      // 检查日志文件大小，如果超过最大值，则清空文件
      final fileStats = await logFile.stat();
      if (fileStats.size > _maxLogFileSize) {
        await logFile.writeAsString(''); // 清空文件
      }

      v('日志服务初始化成功，路径: $_logFilePath');
    } catch (e) {
      debugPrint('初始化日志服务失败: $e');
    }
  }

  /// 获取日志文件内容
  Future<String> getLogContent() async {
    try {
      if (_logFilePath == null) {
        return '日志服务尚未初始化';
      }

      final logFile = File(_logFilePath!);
      if (await logFile.exists()) {
        return await logFile.readAsString();
      } else {
        return '日志文件不存在';
      }
    } catch (e) {
      return '读取日志文件失败: $e';
    }
  }

  /// 清除日志文件
  Future<void> clearLogFile() async {
    try {
      if (_logFilePath == null) {
        return;
      }

      final logFile = File(_logFilePath!);
      if (await logFile.exists()) {
        await logFile.writeAsString('');
        v('日志文件已清空');
      }
    } catch (e) {
      debugPrint('清空日志文件失败: $e');
    }
  }

  /// 日志记录方法 - 详细日志
  void v(String message, {String? tag}) {
    _log(LogLevel.verbose, message, tag: tag);
  }

  /// 日志记录方法 - 调试日志
  void d(String message, {String? tag}) {
    _log(LogLevel.debug, message, tag: tag);
  }

  /// 日志记录方法 - 信息日志
  void i(String message, {String? tag}) {
    _log(LogLevel.info, message, tag: tag);
  }

  /// 日志记录方法 - 警告日志
  void w(String message, {String? tag}) {
    _log(LogLevel.warning, message, tag: tag);
  }

  /// 日志记录方法 - 错误日志
  void e(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    String errorMsg = message;
    if (error != null) {
      errorMsg += '\nError: $error';
    }
    if (stackTrace != null) {
      errorMsg += '\nStackTrace: $stackTrace';
    }
    _log(LogLevel.error, errorMsg, tag: tag);
  }

  /// 记录用户活动，自动脱敏敏感数据
  void logUserAction(String action, {Map<String, dynamic>? data, String? tag}) {
    // 处理数据，脱敏敏感信息
    String? safeData;

    if (data != null && data.isNotEmpty) {
      final Map<String, dynamic> sanitizedData = {};

      for (final entry in data.entries) {
        // 对敏感字段进行脱敏处理
        if (_isSensitiveField(entry.key)) {
          sanitizedData[entry.key] = _sanitizeData(entry.value);
        } else {
          sanitizedData[entry.key] = entry.value;
        }
      }

      safeData = sanitizedData.toString();
    }

    final logMessage =
        safeData != null ? '用户操作: $action, 数据: $safeData' : '用户操作: $action';

    i(logMessage, tag: tag ?? 'USER');
  }

  /// 记录应用状态变化
  void logAppState(String state, {String? details, String? tag}) {
    final logMessage =
        details != null ? '应用状态: $state, 详情: $details' : '应用状态: $state';

    i(logMessage, tag: tag ?? 'APP_STATE');
  }

  /// 记录页面访问
  void logPageVisit(String pageName, {String? tag}) {
    i('页面访问: $pageName', tag: tag ?? 'NAVIGATION');
  }

  /// 记录网络请求
  void logNetworkRequest(String endpoint,
      {String? method, int? statusCode, String? tag}) {
    String logMessage = '网络请求: $endpoint';

    if (method != null) {
      logMessage += ', 方法: $method';
    }

    if (statusCode != null) {
      logMessage += ', 状态码: $statusCode';
    }

    i(logMessage, tag: tag ?? 'NETWORK');
  }

  /// 判断字段是否为敏感信息
  bool _isSensitiveField(String fieldName) {
    // 定义敏感字段列表
    const sensitiveFields = [
      'date',
      '日期',
      'birthday',
      '生日',
      'phone',
      '电话',
      'email',
      '邮箱',
      'address',
      '地址',
      'name',
      '姓名',
      'password',
      '密码',
      'shift',
      '班次',
      'schedule',
      '排班',
      'salary',
      '薪资',
      'pay',
      '工资'
    ];

    return sensitiveFields
        .any((field) => fieldName.toLowerCase().contains(field.toLowerCase()));
  }

  /// 对敏感数据进行脱敏处理
  dynamic _sanitizeData(dynamic value) {
    if (value is String) {
      if (value.length <= 2) {
        return '**';
      } else if (value.length <= 5) {
        return '${value.substring(0, 1)}${'*' * (value.length - 1)}';
      } else {
        return '${value.substring(0, 2)}${'*' * (value.length - 4)}${value.substring(value.length - 2)}';
      }
    } else if (value is DateTime) {
      // 对日期数据只保留年份和月份
      return '${value.year}-${value.month}-**';
    } else if (value is List) {
      return '[数据列表，${value.length}项]';
    } else if (value is Map) {
      return '{数据对象}';
    } else {
      return '***';
    }
  }

  /// 内部日志记录方法
  void _log(LogLevel level, String message, {String? tag}) {
    // 检查日志级别
    if (level.index < _currentLevel.index) {
      return;
    }

    // 格式化日志消息
    final now = DateTime.now();
    final timeFormat = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');
    final timeStr = timeFormat.format(now);

    // 获取日志级别字符串
    final levelStr = _getLevelString(level);

    // 构建日志消息
    final logMessage = tag != null
        ? '[$timeStr] $levelStr [$tag]: $message'
        : '[$timeStr] $levelStr: $message';

    // 输出到控制台
    _printToConsole(level, logMessage);

    // 写入文件
    if (_writeToFile) {
      _writeToLogFile(logMessage);
    }
  }

  /// 输出到控制台
  void _printToConsole(LogLevel level, String message) {
    switch (level) {
      case LogLevel.verbose:
      case LogLevel.debug:
        debugPrint(message);
        break;
      case LogLevel.info:
        debugPrint('\x1B[34m$message\x1B[0m'); // 蓝色
        break;
      case LogLevel.warning:
        debugPrint('\x1B[33m$message\x1B[0m'); // 黄色
        break;
      case LogLevel.error:
        debugPrint('\x1B[31m$message\x1B[0m'); // 红色
        break;
      default:
        debugPrint(message);
    }
  }

  /// 写入日志文件
  Future<void> _writeToLogFile(String logMessage) async {
    if (_logFilePath == null) {
      return;
    }

    try {
      // 添加到缓冲区
      _logBuffer.add(logMessage);

      // 检查是否需要将缓冲区写入文件
      if (_logBuffer.length >= _maxBufferLines) {
        await _flushBuffer();
      }
    } catch (e) {
      debugPrint('写入日志文件失败: $e');
    }
  }

  /// 将缓冲区内容写入文件
  Future<void> _flushBuffer() async {
    if (_logFilePath == null || _logBuffer.isEmpty) {
      return;
    }

    try {
      final logFile = File(_logFilePath!);
      final content = '${_logBuffer.join('\n')}\n';

      // 追加到文件
      await logFile.writeAsString(content, mode: FileMode.append);

      // 清空缓冲区
      _logBuffer.clear();
    } catch (e) {
      debugPrint('刷新日志缓冲区失败: $e');
    }
  }

  /// 获取日志级别字符串
  String _getLevelString(LogLevel level) {
    switch (level) {
      case LogLevel.verbose:
        return 'VERBOSE';
      case LogLevel.debug:
        return 'DEBUG';
      case LogLevel.info:
        return 'INFO';
      case LogLevel.warning:
        return 'WARNING';
      case LogLevel.error:
        return 'ERROR';
      default:
        return 'UNKNOWN';
    }
  }

  /// 导出日志文件
  Future<String?> exportLogFile() async {
    try {
      // 先将缓冲区内容写入文件
      await _flushBuffer();

      if (_logFilePath == null) {
        return null;
      }

      final logFile = File(_logFilePath!);
      if (await logFile.exists()) {
        // 创建导出目录
        final appDocDir = await getApplicationDocumentsDirectory();
        final exportDir = Directory('${appDocDir.path}/exports');

        if (!await exportDir.exists()) {
          await exportDir.create(recursive: true);
        }

        // 创建导出文件
        final now = DateTime.now();
        final formatter = DateFormat('yyyy-MM-dd_HH-mm-ss');
        final exportPath =
            '${exportDir.path}/app_logs_${formatter.format(now)}.txt';

        // 复制日志文件
        await logFile.copy(exportPath);

        return exportPath;
      }
    } catch (e) {
      debugPrint('导出日志文件失败: $e');
    }

    return null;
  }

  /// 强制将日志缓冲区写入文件
  Future<void> flushLogs() async {
    await _flushBuffer();
  }
}
