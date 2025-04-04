import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import '../../core/config/environment.dart';
import 'package:flutter/foundation.dart';

class BackupService {
  Future<Map<String, dynamic>> getBackupInfo() async {
    try {
      final backupDir = await _getBackupDirectory();
      final backupFile = File('${backupDir.path}/backup.db');

      bool hasBackup = backupFile.existsSync();
      String lastBackupTime = '从未备份';
      String backupSize = '0 KB';

      if (hasBackup) {
        final stat = await backupFile.stat();
        final lastModified = stat.modified;
        lastBackupTime = DateFormat('yyyy-MM-dd HH:mm').format(lastModified);

        final sizeInBytes = stat.size;
        if (sizeInBytes < 1024) {
          backupSize = '$sizeInBytes B';
        } else if (sizeInBytes < 1024 * 1024) {
          backupSize = '${(sizeInBytes / 1024).toStringAsFixed(2)} KB';
        } else {
          backupSize = '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
        }
      }

      return {
        'lastBackupTime': lastBackupTime,
        'backupSize': backupSize,
        'hasBackup': hasBackup,
      };
    } catch (e) {
      return {
        'lastBackupTime': '未知',
        'backupSize': '未知',
        'hasBackup': false,
      };
    }
  }

  Future<void> createBackup() async {
    try {
      // 获取数据库文件路径
      final dbDir = await getDatabasesPath();
      // 使用Environment中定义的数据库名称
      final dbFile = File('$dbDir/${Environment.databaseName}');

      if (!dbFile.existsSync()) {
        throw Exception('数据库文件不存在');
      }

      // 创建备份目录
      final backupDir = await _getBackupDirectory();
      if (!backupDir.existsSync()) {
        await backupDir.create(recursive: true);
      }

      // 使用时间戳创建备份文件名
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final backupFileName = 'backup_$timestamp.db';
      final backupFile = File('${backupDir.path}/$backupFileName');

      // 复制数据库文件到备份目录
      await dbFile.copy(backupFile.path);

      // 同时更新最新备份文件（用于兼容旧代码）
      final latestBackupFile = File('${backupDir.path}/backup.db');
      if (latestBackupFile.existsSync()) {
        await latestBackupFile.delete();
      }
      await dbFile.copy(latestBackupFile.path);

      // 更新最后备份时间
      final prefs = await _getPreferences();
      await prefs.setString(
          'last_backup_time', DateTime.now().toIso8601String());
    } catch (e) {
      throw Exception('创建备份失败: $e');
    }
  }

  Future<void> exportBackup() async {
    try {
      final backupDir = await _getBackupDirectory();
      final backupFile = File('${backupDir.path}/backup.db');

      if (!backupFile.existsSync()) {
        throw Exception('备份文件不存在，请先创建备份');
      }

      // 创建一个带时间戳的备份文件
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final exportFile =
          File('${backupDir.path}/scheduling_assistant_backup_$timestamp.db');
      await backupFile.copy(exportFile.path);

      // 分享备份文件
      await Share.shareXFiles(
        [XFile(exportFile.path)],
        subject: '排班助手数据备份',
        text: '这是您的排班助手数据备份文件，请妥善保管。',
      );
    } catch (e) {
      throw Exception('导出备份失败: $e');
    }
  }

  Future<void> restoreFromLatestBackup() async {
    try {
      final backupDir = await _getBackupDirectory();
      final backupFile = File('${backupDir.path}/backup.db');

      if (!backupFile.existsSync()) {
        throw Exception('备份文件不存在，无法恢复');
      }

      // 获取数据库文件路径
      final dbDir = await getDatabasesPath();
      final dbFile = File('$dbDir/${Environment.databaseName}');

      // 如果数据库文件存在，先创建一个临时备份
      if (dbFile.existsSync()) {
        final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
        final tempBackup = File('$dbDir/temp_backup_$timestamp.db');
        await dbFile.copy(tempBackup.path);
      }

      // 复制备份文件到数据库目录
      await backupFile.copy(dbFile.path);
    } catch (e) {
      throw Exception('从最新备份恢复失败: $e');
    }
  }

  Future<void> restoreFromFile() async {
    try {
      // 使用文件选择器选择备份文件
      const params = OpenFileDialogParams(
        fileExtensionsFilter: ['db'],
        mimeTypesFilter: ['application/octet-stream'],
      );

      final filePath = await FlutterFileDialog.pickFile(params: params);

      if (filePath == null) {
        throw Exception('未选择备份文件');
      }

      final backupFile = File(filePath);
      if (!backupFile.existsSync()) {
        throw Exception('选择的备份文件不存在');
      }

      // 获取数据库文件路径
      final dbDir = await getDatabasesPath();
      final dbFile = File('$dbDir/${Environment.databaseName}');

      // 如果数据库文件存在，先创建一个临时备份
      if (dbFile.existsSync()) {
        final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
        final tempBackup = File('$dbDir/temp_backup_$timestamp.db');
        await dbFile.copy(tempBackup.path);
      }

      // 复制选择的备份文件到数据库目录
      await backupFile.copy(dbFile.path);
    } catch (e) {
      throw Exception('从文件恢复失败: $e');
    }
  }

  Future<void> clearCache() async {
    try {
      final cacheDir = await getTemporaryDirectory();

      if (cacheDir.existsSync()) {
        // 删除缓存目录中的所有文件
        final entities = cacheDir.listSync();
        for (var entity in entities) {
          if (entity is File) {
            await entity.delete();
          } else if (entity is Directory) {
            await entity.delete(recursive: true);
          }
        }
      }
    } catch (e) {
      throw Exception('清除缓存失败: $e');
    }
  }

  Future<void> clearAllData() async {
    try {
      // 清除数据库
      final dbDir = await getDatabasesPath();
      final dbFile = File('$dbDir/${Environment.databaseName}');

      if (dbFile.existsSync()) {
        await dbFile.delete();
      }

      // 清除备份
      final backupDir = await _getBackupDirectory();
      if (backupDir.existsSync()) {
        await backupDir.delete(recursive: true);
      }

      // 清除缓存
      await clearCache();

      // 清除偏好设置
      final prefs = await _getPreferences();
      await prefs.clear();
    } catch (e) {
      throw Exception('清除所有数据失败: $e');
    }
  }

  Future<Directory> _getBackupDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    return Directory('${appDir.path}/backups');
  }

  Future<dynamic> _getPreferences() async {
    // 这个方法用于获取SharedPreferences实例，用于存储和读取应用的配置信息
    // 在实际应用中应该使用shared_preferences包，但当前为了简化示例使用模拟对象
    // 主要用于clearAllData方法中清除用户偏好设置
    return _MockPreferences();
  }

  // 获取数据库路径
  Future<String> getDatabasesPath() async {
    return await sqflite.getDatabasesPath();
  }

  // 获取最新的备份文件
  Future<File> getLatestBackupFile() async {
    final backupDir = await _getBackupDirectory();
    final backupFile = File('${backupDir.path}/backup.db');

    if (!backupFile.existsSync()) {
      throw Exception('备份文件不存在');
    }

    return backupFile;
  }

  // 获取所有备份文件
  Future<List<Map<String, dynamic>>> getAllBackups() async {
    try {
      final backupDir = await _getBackupDirectory();
      if (!backupDir.existsSync()) {
        return [];
      }

      // 获取所有.db文件
      final List<FileSystemEntity> entities = await backupDir.list().toList();
      final List<File> backupFiles = entities
          .whereType<File>()
          .where((file) =>
              file.path.endsWith('.db') && !file.path.endsWith('/backup.db'))
          .toList();

      // 按修改时间排序（最新的在前）
      backupFiles.sort((a, b) {
        return b.lastModifiedSync().compareTo(a.lastModifiedSync());
      });

      // 构建备份信息列表
      final List<Map<String, dynamic>> backupInfoList = [];
      for (var file in backupFiles) {
        final stat = await file.stat();
        final lastModified = stat.modified;
        final backupTime = DateFormat('yyyy-MM-dd HH:mm').format(lastModified);

        final sizeInBytes = stat.size;
        String fileSize;
        if (sizeInBytes < 1024) {
          fileSize = '$sizeInBytes B';
        } else if (sizeInBytes < 1024 * 1024) {
          fileSize = '${(sizeInBytes / 1024).toStringAsFixed(2)} KB';
        } else {
          fileSize = '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
        }

        backupInfoList.add({
          'fileName': file.path.split('/').last,
          'filePath': file.path,
          'backupTime': backupTime,
          'fileSize': fileSize,
          'timestamp': lastModified.millisecondsSinceEpoch,
        });
      }

      return backupInfoList;
    } catch (e) {
      debugPrint('获取备份列表失败: $e');
      return [];
    }
  }

  // 从指定备份文件恢复
  Future<void> restoreFromBackupFile(String backupFilePath) async {
    try {
      final backupFile = File(backupFilePath);

      if (!backupFile.existsSync()) {
        throw Exception('备份文件不存在，无法恢复');
      }

      // 获取数据库文件路径
      final dbDir = await getDatabasesPath();
      final dbFile = File('$dbDir/${Environment.databaseName}');

      // 如果数据库文件存在，先创建一个临时备份
      if (dbFile.existsSync()) {
        final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
        final tempBackup = File('$dbDir/temp_backup_$timestamp.db');
        await dbFile.copy(tempBackup.path);
      }

      // 复制备份文件到数据库目录
      await backupFile.copy(dbFile.path);
    } catch (e) {
      throw Exception('从备份文件恢复失败: $e');
    }
  }
}

// 模拟 SharedPreferences 类，实际应用中应该使用 shared_preferences 包
class _MockPreferences {
  Future<bool> setString(String key, String value) async {
    return true;
  }

  Future<bool> clear() async {
    return true;
  }
}
