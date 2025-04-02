import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';
import '../../core/config/environment.dart';
import 'daos/shift_dao.dart';
import 'daos/alarm_dao.dart';
import 'daos/shift_type_dao.dart';

class DatabaseProvider {
  static Database? _database;
  static DatabaseProvider? _instance;
  late ShiftDao _shiftDao;
  late AlarmEntityDao _alarmDao;
  late ShiftTypeDao _shiftTypeDao;

  DatabaseProvider._();

  static Future<DatabaseProvider> initialize() async {
    if (_instance == null) {
      _instance = DatabaseProvider._();
      await _instance!._initDatabase();
      _instance!._shiftDao = ShiftDao(_database!);
      _instance!._alarmDao = AlarmEntityDao(_database!);
      _instance!._shiftTypeDao = ShiftTypeDao(_database!);
    }
    return _instance!;
  }

  ShiftDao get shiftDao => _shiftDao;
  AlarmEntityDao get alarmDao => _alarmDao;
  ShiftTypeDao get shiftTypeDao => _shiftTypeDao;

  Future<Database> get database async {
    if (_database != null) return _database!;
    await _initDatabase();
    return _database!;
  }

  Future<void> _initDatabase() async {
    try {
      final String path = join(
        await getDatabasesPath(),
        Environment.databaseName,
      );
      debugPrint('数据库路径: $path');
      debugPrint('数据库版本: ${Environment.databaseVersion}');
      debugPrint('环境: ${Environment.isDevelopment ? '开发' : '生产'}');

      // 检查是否需要重新创建数据库
      final shouldRecreate = await Environment.shouldRecreateDatabase;
      if (shouldRecreate) {
        debugPrint('开发环境：检测到表结构变化，删除现有数据库');
        await deleteDatabase(path);
      }

      _database = await openDatabase(
        path,
        version: Environment.databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onDowngrade: Environment.isDevelopment
            ? onDatabaseDowngradeDelete
            : _onDowngrade,
      );

      // 检查数据库表
      final tables = await _database!.query(
        'sqlite_master',
        columns: ['name'],
        where: 'type = ?',
        whereArgs: ['table'],
      );
      debugPrint('数据库中的表: ${tables.map((t) => t['name']).join(', ')}');

      // 手动检查alarm_entities表中是否有syncToSystem列
      await _ensureAlarmEntitiesTableColumns(_database!);

      debugPrint('数据库初始化完成');
    } catch (e) {
      debugPrint('数据库初始化失败: $e');
      rethrow;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    debugPrint('创建数据库，版本: $version');
    try {
      // 创建班次表
      await db.execute('''
        CREATE TABLE IF NOT EXISTS shifts (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT NOT NULL,
          type TEXT NOT NULL,
          shiftTypeId INTEGER NOT NULL,
          startTime TEXT,
          endTime TEXT,
          note TEXT,
          noteUpdatedAt INTEGER NOT NULL,
          updateTime INTEGER NOT NULL
        )
      ''');

      // 创建班次表索引
      await db.execute(
        'CREATE UNIQUE INDEX IF NOT EXISTS index_shifts_date ON shifts (date)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS index_shifts_note_updated_at ON shifts (noteUpdatedAt)',
      );

      // 创建班次模板表
      await db.execute('''
        CREATE TABLE IF NOT EXISTS shift_templates (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          startTime TEXT,
          endTime TEXT,
          color INTEGER NOT NULL,
          updateTime INTEGER NOT NULL,
          type TEXT NOT NULL
        )
      ''');

      // 创建闹钟表
      await db.execute('''
        CREATE TABLE IF NOT EXISTS alarms (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          hoursBefore INTEGER NOT NULL,
          minutesBefore INTEGER NOT NULL,
          enabled INTEGER NOT NULL DEFAULT 1
        )
      ''');

      // 创建自定义闹钟表
      await db.execute('''
        CREATE TABLE IF NOT EXISTS alarm_entities (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          timeInMillis INTEGER NOT NULL,
          enabled INTEGER NOT NULL DEFAULT 1,
          repeat INTEGER NOT NULL DEFAULT 0,
          repeatDays INTEGER NOT NULL DEFAULT 0,
          soundUri TEXT,
          vibrate INTEGER NOT NULL DEFAULT 1,
          createTime INTEGER NOT NULL,
          updateTime INTEGER NOT NULL,
          snoozeInterval INTEGER NOT NULL DEFAULT 5,
          maxSnoozeCount INTEGER NOT NULL DEFAULT 3,
          syncToSystem INTEGER NOT NULL DEFAULT 0
        )
      ''');

      // 创建班次类型表
      await db.execute('''
        CREATE TABLE IF NOT EXISTS shift_types (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          startTime TEXT,
          endTime TEXT,
          color INTEGER NOT NULL,
          isPreset INTEGER NOT NULL DEFAULT 0,
          isRestDay INTEGER NOT NULL DEFAULT 0,
          updateTime INTEGER NOT NULL
        )
      ''');
      debugPrint('数据库表创建完成');
    } catch (e) {
      debugPrint('创建数据库表失败: $e');
      rethrow;
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('升级数据库，从版本 $oldVersion 到 $newVersion');
    try {
      if (oldVersion < 103) {
        // 在这里添加数据迁移逻辑
        await _migrateToVersion103(db);
      }
      if (oldVersion < 104) {
        // 版本104：为alarm_entities表添加syncToSystem列
        await _migrateToVersion104(db);
      }
      // 在这里添加未来版本的迁移逻辑
    } catch (e) {
      debugPrint('数据库升级失败: $e');
      rethrow;
    }
  }

  Future<void> _onDowngrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('降级数据库，从版本 $oldVersion 到 $newVersion');
    // 在生产环境中，我们应该提供向下兼容的迁移方案
    // 这里可以根据需要实现具体的降级逻辑
  }

  Future<void> _migrateToVersion103(Database db) async {
    debugPrint('执行版本 103 的升级...');
    // 创建班次类型表
    await db.execute('''
      CREATE TABLE IF NOT EXISTS shift_types (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        startTime TEXT,
        endTime TEXT,
        color INTEGER NOT NULL,
        isPreset INTEGER NOT NULL DEFAULT 0,
        isRestDay INTEGER NOT NULL DEFAULT 0,
        updateTime INTEGER NOT NULL
      )
    ''');
    debugPrint('版本 103 升级完成');
  }

  Future<void> _migrateToVersion104(Database db) async {
    debugPrint('执行版本 104 的升级...');
    try {
      // 检查syncToSystem列是否已存在
      final List<Map<String, dynamic>> columns = await db.rawQuery(
        "PRAGMA table_info('alarm_entities')",
      );
      final syncColumnExists = columns.any(
        (col) => col['name'] == 'syncToSystem',
      );

      // 只有当列不存在时才添加
      if (!syncColumnExists) {
        await db.execute(
          'ALTER TABLE alarm_entities ADD COLUMN syncToSystem INTEGER NOT NULL DEFAULT 0',
        );
        debugPrint('为alarm_entities表添加syncToSystem列成功');
      } else {
        debugPrint('alarm_entities表已有syncToSystem列，跳过');
      }
    } catch (e) {
      debugPrint('添加syncToSystem列失败: $e');
      rethrow;
    }
    debugPrint('版本 104 升级完成');
  }

  // 确保alarm_entities表中有所有需要的列
  Future<void> _ensureAlarmEntitiesTableColumns(Database db) async {
    try {
      debugPrint('检查alarm_entities表的列...');
      final List<Map<String, dynamic>> columns = await db.rawQuery(
        "PRAGMA table_info('alarm_entities')",
      );

      // 检查每个必要的列是否存在
      final columnNames = columns.map((col) => col['name'] as String).toList();
      debugPrint('alarm_entities表的列: $columnNames');

      // 检查syncToSystem列是否存在
      if (!columnNames.contains('syncToSystem')) {
        debugPrint('syncToSystem列不存在，尝试添加...');
        try {
          await db.execute(
            'ALTER TABLE alarm_entities ADD COLUMN syncToSystem INTEGER NOT NULL DEFAULT 0',
          );
          debugPrint('手动添加syncToSystem列成功');
        } catch (e) {
          debugPrint('手动添加syncToSystem列失败: $e');

          // 如果添加列失败，可能是因为表结构有问题，尝试重建表
          await _recreateAlarmEntitiesTable(db);
        }
      } else {
        debugPrint('syncToSystem列已存在');
      }
    } catch (e) {
      debugPrint('检查alarm_entities表的列失败: $e');
      // 出错时尝试重建表
      await _recreateAlarmEntitiesTable(db);
    }
  }

  // 重建alarm_entities表
  Future<void> _recreateAlarmEntitiesTable(Database db) async {
    debugPrint('开始重建alarm_entities表...');
    try {
      // 1. 备份现有数据
      List<Map<String, dynamic>> existingData = [];
      try {
        existingData = await db.query('alarm_entities');
        debugPrint('已备份${existingData.length}条闹钟数据');
      } catch (e) {
        debugPrint('备份数据失败，将创建空表: $e');
      }

      // 2. 删除旧表
      try {
        await db.execute('DROP TABLE IF EXISTS alarm_entities');
        debugPrint('已删除旧的alarm_entities表');
      } catch (e) {
        debugPrint('删除旧表失败: $e');
      }

      // 3. 创建新表
      await db.execute('''
        CREATE TABLE IF NOT EXISTS alarm_entities (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          timeInMillis INTEGER NOT NULL,
          enabled INTEGER NOT NULL DEFAULT 1,
          repeat INTEGER NOT NULL DEFAULT 0,
          repeatDays INTEGER NOT NULL DEFAULT 0,
          soundUri TEXT,
          vibrate INTEGER NOT NULL DEFAULT 1,
          createTime INTEGER NOT NULL,
          updateTime INTEGER NOT NULL,
          snoozeInterval INTEGER NOT NULL DEFAULT 5,
          maxSnoozeCount INTEGER NOT NULL DEFAULT 3,
          syncToSystem INTEGER NOT NULL DEFAULT 0
        )
      ''');
      debugPrint('已创建新的alarm_entities表');

      // 4. 恢复数据
      if (existingData.isNotEmpty) {
        for (var data in existingData) {
          // 确保data中包含所有必要的字段
          data.putIfAbsent('syncToSystem', () => 0);
          try {
            await db.insert('alarm_entities', data);
          } catch (e) {
            debugPrint('恢复数据项失败: $e');
            // 继续处理下一条数据
          }
        }
        debugPrint('已恢复闹钟数据');
      }

      debugPrint('alarm_entities表重建完成');
    } catch (e) {
      debugPrint('重建alarm_entities表失败: $e');
      rethrow;
    }
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
