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
      final String path = join(await getDatabasesPath(), Environment.databaseName);
      debugPrint('数据库路径: $path');
      debugPrint('数据库版本: ${Environment.databaseVersion}');
      debugPrint('环境: ${Environment.isDevelopment ? '开发' : '生产'}');
      
      if (Environment.shouldRecreateDatabase) {
        debugPrint('开发环境：删除现有数据库');
        await deleteDatabase(path);
      }
      
      _database = await openDatabase(
        path,
        version: Environment.databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onDowngrade: onDatabaseDowngradeDelete,
      );
      
      // 检查数据库表
      final tables = await _database!.query('sqlite_master', 
        columns: ['name'], 
        where: 'type = ?', 
        whereArgs: ['table']
      );
      debugPrint('数据库中的表: ${tables.map((t) => t['name']).join(', ')}');
      
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
          maxSnoozeCount INTEGER NOT NULL DEFAULT 3
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
      debugPrint('班次类型表创建成功');
    } catch (e) {
      debugPrint('创建数据库表失败: $e');
      rethrow;
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('升级数据库，从版本 $oldVersion 到 $newVersion');
    try {
      if (oldVersion < 103) {
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
        debugPrint('班次类型表创建成功');
      }
    } catch (e) {
      debugPrint('数据库升级失败: $e');
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