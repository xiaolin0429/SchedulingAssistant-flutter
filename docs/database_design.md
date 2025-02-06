# 排班助手数据库设计文档 (Flutter/Dart 版本)

## 1. 数据库概述

### 1.1 基本信息
- 数据库类型：SQLite（使用 sqflite 包）
- 当前版本：102
- 数据库名称：schedule_assistant.db

### 1.2 技术特点
- 采用 sqflite 数据库框架
- 实现数据访问对象（DAO）模式
- 支持 StreamController 响应式数据更新
- 使用 JSON 序列化处理复杂数据类型
- 实现完整的数据库迁移策略

## 2. 数据表结构

### 2.1 班次表（shifts）
管理用户的排班信息
```dart
// shifts 表的索引
// CREATE UNIQUE INDEX IF NOT EXISTS `index_shifts_date` ON shifts (`date`);
// CREATE INDEX IF NOT EXISTS `index_shifts_note_updated_at` ON shifts (`note_updated_at`);

class Shift {
  final int? id; // 自增主键
  final String date; // 非空，唯一索引
  final ShiftType type; // 非空，枚举类型
  final int shiftTypeId;
  final String? startTime;
  final String? endTime;
  final String? note;
  final int noteUpdatedAt; // 非空，索引
  final int updateTime;
  final bool isNewlyAdded; // @Ignore 在数据库中不存储

  Shift({
    this.id,
    required this.date,
    required this.type,
    required this.shiftTypeId,
    this.startTime,
    this.endTime,
    this.note,
    required this.noteUpdatedAt,
    required this.updateTime,
    this.isNewlyAdded = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'date': date,
    'type': type.toString(),
    'shiftTypeId': shiftTypeId,
    'startTime': startTime,
    'endTime': endTime,
    'note': note,
    'noteUpdatedAt': noteUpdatedAt,
    'updateTime': updateTime,
  };

  factory Shift.fromMap(Map<String, dynamic> map) => Shift(
    id: map['id'] as int?,
    date: map['date'] as String,
    type: ShiftType.values.firstWhere(
      (e) => e.toString() == map['type'],
      orElse: () => ShiftType.custom,
    ),
    shiftTypeId: map['shiftTypeId'] as int,
    startTime: map['startTime'] as String?,
    endTime: map['endTime'] as String?,
    note: map['note'] as String?,
    noteUpdatedAt: map['noteUpdatedAt'] as int,
    updateTime: map['updateTime'] as int,
  );
}

// 班次类型枚举
enum ShiftType {
  dayShift,    // 早班
  nightShift,  // 晚班
  restDay,     // 休息
  custom       // 自定义
}

// 排序选项枚举
enum SortOption {
  dateAsc,     // 按日期升序
  dateDesc,    // 按日期降序
  type,        // 按类型
  updateTime   // 按更新时间
}
```

### 2.2 班次模板表（shift_templates）
存储预定义的班次模板
```dart
class ShiftTemplate {
  final int? id;
  final String name; // 非空
  final String? startTime;
  final String? endTime;
  final int color;
  final bool isDefault;
  final int updateTime;
  final ShiftType type;

  ShiftTemplate({
    this.id,
    required this.name,
    this.startTime,
    this.endTime,
    required this.color,
    required this.isDefault,
    required this.updateTime,
    required this.type,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'startTime': startTime,
    'endTime': endTime,
    'color': color,
    'isDefault': isDefault ? 1 : 0,
    'updateTime': updateTime,
    'type': type.toString(),
  };

  factory ShiftTemplate.fromMap(Map<String, dynamic> map) => ShiftTemplate(
    id: map['id'] as int?,
    name: map['name'] as String,
    startTime: map['startTime'] as String?,
    endTime: map['endTime'] as String?,
    color: map['color'] as int,
    isDefault: (map['isDefault'] as int) == 1,
    updateTime: map['updateTime'] as int,
    type: ShiftType.values.firstWhere(
      (e) => e.toString() == map['type'],
      orElse: () => ShiftType.custom,
    ),
  );
}
```

### 2.3 班次类型表（shift_types）
定义不同类型的班次
```dart
class ShiftType {
  final int? id;
  final String name; // 非空
  final String? startTime;
  final String? endTime;
  final int color;
  final bool isDefault;
  final int updateTime;

  ShiftType({
    this.id,
    required this.name,
    this.startTime,
    this.endTime,
    required this.color,
    required this.isDefault,
    required this.updateTime,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'startTime': startTime,
    'endTime': endTime,
    'color': color,
    'isDefault': isDefault ? 1 : 0,
    'updateTime': updateTime,
  };

  factory ShiftType.fromMap(Map<String, dynamic> map) => ShiftType(
    id: map['id'] as int?,
    name: map['name'] as String,
    startTime: map['startTime'] as String?,
    endTime: map['endTime'] as String?,
    color: map['color'] as int,
    isDefault: (map['isDefault'] as int) == 1,
    updateTime: map['updateTime'] as int,
  );
}
```

### 2.4 闹钟表（alarms）
管理提醒功能

```dart
// 基础闹钟实体 - 用于班次提醒
class Alarm {
  final int? id;
  final int hoursBefore;    // 提前小时数
  final int minutesBefore;  // 提前分钟数
  final bool enabled;       // 是否启用

  Alarm({
    this.id,
    required this.hoursBefore,
    required this.minutesBefore,
    this.enabled = true,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'hoursBefore': hoursBefore,
    'minutesBefore': minutesBefore,
    'enabled': enabled ? 1 : 0,
  };

  factory Alarm.fromMap(Map<String, dynamic> map) => Alarm(
    id: map['id'] as int?,
    hoursBefore: map['hoursBefore'] as int,
    minutesBefore: map['minutesBefore'] as int,
    enabled: (map['enabled'] as int) == 1,
  );
}

// 扩展闹钟实体 - 用于自定义闹钟
class AlarmEntity {
  final int? id;
  final String? name;           // 闹钟名称
  final int timeInMillis;       // 闹钟时间（毫秒）
  final bool enabled;           // 是否启用
  final bool repeat;            // 是否重复
  final int repeatDays;         // 重复日期（位图：周日=1，周一=2，周二=4，以此类推）
  final String? soundUri;       // 铃声URI
  final bool vibrate;           // 是否震动
  final int createTime;         // 创建时间
  final int updateTime;         // 更新时间
  final int snoozeInterval;     // 贪睡间隔（分钟）
  final int maxSnoozeCount;     // 最大贪睡次数

  AlarmEntity({
    this.id,
    this.name,
    required this.timeInMillis,
    this.enabled = true,
    this.repeat = false,
    this.repeatDays = 0,
    this.soundUri,
    this.vibrate = true,
    int? createTime,
    int? updateTime,
    this.snoozeInterval = 5,    // 默认5分钟
    this.maxSnoozeCount = 3,    // 默认3次
  }) : 
    this.createTime = createTime ?? DateTime.now().millisecondsSinceEpoch,
    this.updateTime = updateTime ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'timeInMillis': timeInMillis,
    'enabled': enabled ? 1 : 0,
    'repeat': repeat ? 1 : 0,
    'repeatDays': repeatDays,
    'soundUri': soundUri,
    'vibrate': vibrate ? 1 : 0,
    'createTime': createTime,
    'updateTime': updateTime,
    'snoozeInterval': snoozeInterval,
    'maxSnoozeCount': maxSnoozeCount,
  };

  factory AlarmEntity.fromMap(Map<String, dynamic> map) => AlarmEntity(
    id: map['id'] as int?,
    name: map['name'] as String?,
    timeInMillis: map['timeInMillis'] as int,
    enabled: (map['enabled'] as int) == 1,
    repeat: (map['repeat'] as int) == 1,
    repeatDays: map['repeatDays'] as int,
    soundUri: map['soundUri'] as String?,
    vibrate: (map['vibrate'] as int) == 1,
    createTime: map['createTime'] as int,
    updateTime: map['updateTime'] as int,
    snoozeInterval: map['snoozeInterval'] as int,
    maxSnoozeCount: map['maxSnoozeCount'] as int,
  );
}
```

### 2.5 用户资料表（user_profile）
存储用户基本信息
```dart
class UserProfile {
  final int? id;
  final String? name;
  final String? imageUri;
  final String? email;
  final String? phone;  // 添加电话字段

  UserProfile({
    this.id,
    this.name,
    this.imageUri,
    this.email,
    this.phone,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'imageUri': imageUri,
    'email': email,
    'phone': phone,
  };

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
    id: map['id'] as int?,
    name: map['name'] as String?,
    imageUri: map['imageUri'] as String?,
    email: map['email'] as String?,
    phone: map['phone'] as String?,
  );
}
```

### 2.6 用户设置表（user_settings）
管理应用配置
```dart
class UserSettings {
  final int? id;
  final int themeMode;         // 0-跟随系统，1-浅色，2-深色
  final int languageMode;      // 0-跟随系统，1-中文，2-英文
  final bool notificationEnabled;
  final int notificationAdvanceTime;
  final bool syncSystemAlarm;

  UserSettings({
    this.id,
    this.themeMode = 0,
    this.languageMode = 0,
    this.notificationEnabled = true,
    this.notificationAdvanceTime = 30,
    this.syncSystemAlarm = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'themeMode': themeMode,
    'languageMode': languageMode,
    'notificationEnabled': notificationEnabled ? 1 : 0,
    'notificationAdvanceTime': notificationAdvanceTime,
    'syncSystemAlarm': syncSystemAlarm ? 1 : 0,
  };

  factory UserSettings.fromMap(Map<String, dynamic> map) => UserSettings(
    id: map['id'] as int?,
    themeMode: map['themeMode'] as int,
    languageMode: map['languageMode'] as int,
    notificationEnabled: (map['notificationEnabled'] as int) == 1,
    notificationAdvanceTime: map['notificationAdvanceTime'] as int,
    syncSystemAlarm: (map['syncSystemAlarm'] as int) == 1,
  );
}
```

## 3. 数据库创建和迁移

### 3.1 数据库创建
```dart
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'schedule_assistant.db');
    return await openDatabase(
      path,
      version: 102,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 创建班次表
    await db.execute('''
      CREATE TABLE shifts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        shiftTypeId INTEGER NOT NULL,
        startTime TEXT,
        endTime TEXT,
        note TEXT,
        noteUpdatedAt INTEGER NOT NULL,
        updateTime INTEGER
      )
    ''');

    // 创建班次类型表
    await db.execute('''
      CREATE TABLE shift_types (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        startTime TEXT,
        endTime TEXT,
        color INTEGER NOT NULL,
        isDefault INTEGER NOT NULL,
        updateTime INTEGER NOT NULL
      )
    ''');

    // 创建班次模板表
    await db.execute('''
      CREATE TABLE shift_templates (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        startTime TEXT,
        endTime TEXT,
        color INTEGER NOT NULL,
        isDefault INTEGER NOT NULL,
        updateTime INTEGER NOT NULL,
        type TEXT NOT NULL
      )
    ''');

    // 创建基础闹钟表
    await db.execute('''
      CREATE TABLE alarms (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        hoursBefore INTEGER NOT NULL,
        minutesBefore INTEGER NOT NULL,
        enabled INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // 创建扩展闹钟表
    await db.execute('''
      CREATE TABLE alarm_entities (
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
        snoozeInterval INTEGER DEFAULT 5,
        maxSnoozeCount INTEGER DEFAULT 3
      )
    ''');

    // 创建用户资料表
    await db.execute('''
      CREATE TABLE user_profile (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        imageUri TEXT,
        email TEXT,
        phone TEXT
      )
    ''');

    // 创建用户设置表
    await db.execute('''
      CREATE TABLE user_settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        themeMode INTEGER NOT NULL DEFAULT 0,
        languageMode INTEGER NOT NULL DEFAULT 0,
        notificationEnabled INTEGER NOT NULL DEFAULT 1,
        notificationAdvanceTime INTEGER NOT NULL DEFAULT 30,
        syncSystemAlarm INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // 创建索引
    await db.execute(
      'CREATE UNIQUE INDEX index_shifts_date ON shifts (date)'
    );
    await db.execute(
      'CREATE INDEX index_shifts_note_updated_at ON shifts (noteUpdatedAt)'
    );
  }
}
```

### 3.2 数据库迁移
```dart
Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  // 版本 1 -> 2：添加 updateTime 字段
  if (oldVersion < 2) {
    await db.execute(
      'ALTER TABLE shifts ADD COLUMN updateTime INTEGER DEFAULT 0'
    );
    await db.execute(
      'ALTER TABLE shift_templates ADD COLUMN updateTime INTEGER DEFAULT 0'
    );
  }

  // 版本 2 -> 3：创建班次类型表
  if (oldVersion < 3) {
    await db.execute('''
      CREATE TABLE shift_types (
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        name TEXT NOT NULL,
        startTime TEXT,
        endTime TEXT,
        color INTEGER NOT NULL,
        isDefault INTEGER NOT NULL,
        updateTime INTEGER NOT NULL,
        type TEXT
      )
    ''');
  }

  // 版本 3 -> 4：创建闹钟表
  if (oldVersion < 4) {
    await db.execute('''
      CREATE TABLE alarms (
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        name TEXT,
        timeInMillis INTEGER NOT NULL,
        enabled INTEGER NOT NULL DEFAULT 1,
        repeat INTEGER NOT NULL DEFAULT 0,
        repeatDays INTEGER NOT NULL DEFAULT 0,
        soundUri TEXT,
        vibrate INTEGER NOT NULL DEFAULT 1
      )
    ''');
  }

  // 版本 4 -> 5：添加 shiftTypeId 字段
  if (oldVersion < 5) {
    await db.execute(
      'ALTER TABLE shifts ADD COLUMN shiftTypeId INTEGER NOT NULL DEFAULT 0'
    );
  }

  // 版本 5 -> 6：重建班次类型表
  if (oldVersion < 6) {
    await db.execute('''
      CREATE TABLE shift_types_temp (
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        name TEXT NOT NULL,
        startTime TEXT,
        endTime TEXT,
        color INTEGER NOT NULL,
        isDefault INTEGER NOT NULL,
        updateTime INTEGER NOT NULL
      )
    ''');

    await db.execute(
      'INSERT INTO shift_types_temp SELECT id, name, startTime, endTime, color, isDefault, updateTime FROM shift_types'
    );
    await db.execute('DROP TABLE shift_types');
    await db.execute('ALTER TABLE shift_types_temp RENAME TO shift_types');
  }

  // 版本 6 -> 7：添加闹钟相关字段
  if (oldVersion < 7) {
    await db.execute(
      'ALTER TABLE alarms ADD COLUMN createTime INTEGER NOT NULL DEFAULT 0'
    );
    await db.execute(
      'ALTER TABLE alarms ADD COLUMN updateTime INTEGER NOT NULL DEFAULT 0'
    );
    await db.execute(
      'ALTER TABLE alarms RENAME COLUMN time TO timeInMillis'
    );
  }

  // 版本 7 -> 8：创建用户资料表
  if (oldVersion < 8) {
    await db.execute('''
      CREATE TABLE user_profile (
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        name TEXT,
        imageUri TEXT
      )
    ''');
  }

  // 版本 8 -> 9：添加用户资料表字段
  if (oldVersion < 9) {
    await db.execute('ALTER TABLE user_profile ADD COLUMN email TEXT');
    await db.execute('ALTER TABLE user_profile ADD COLUMN phone TEXT');
  }

  // 版本 9 -> 10：重建用户资料表
  if (oldVersion < 10) {
    await db.execute('''
      CREATE TABLE user_profile_new (
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        name TEXT,
        imageUri TEXT,
        email TEXT
      )
    ''');
    await db.execute(
      'INSERT INTO user_profile_new SELECT id, name, imageUri, email FROM user_profile'
    );
    await db.execute('DROP TABLE user_profile');
    await db.execute('ALTER TABLE user_profile_new RENAME TO user_profile');
  }

  // 版本 100 -> 101：创建用户设置表
  if (oldVersion < 101) {
    await db.execute('''
      CREATE TABLE user_settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        themeMode INTEGER NOT NULL DEFAULT 0,
        languageMode INTEGER NOT NULL DEFAULT 0,
        notificationEnabled INTEGER NOT NULL DEFAULT 1,
        notificationAdvanceTime INTEGER NOT NULL DEFAULT 30
      )
    ''');
  }
}
```

## 4. 数据访问层

### 4.1 DAO 接口
```dart
// 班次 DAO
abstract class ShiftDao {
  Future<void> insert(Shift shift);
  Future<void> update(Shift shift);
  Future<void> delete(int id);
  Stream<List<Shift>> getAllShifts();
  Future<List<Shift>> getAllShiftsSync();
  Future<List<Shift>> getShiftsBetween(String startDate, String endDate);
  Future<Shift?> getShiftByDate(String date);
  Future<Shift?> getShiftByDateDirect(String date);
  Future<List<Shift>> getShiftsWithNotes();
}

// 班次类型 DAO
abstract class ShiftTypeDao {
  Future<void> insert(ShiftTypeEntity shiftType);
  Future<void> update(ShiftTypeEntity shiftType);
  Future<void> delete(ShiftTypeEntity shiftType);
  Stream<List<ShiftTypeEntity>> getAllShiftTypes();
  Future<List<ShiftTypeEntity>> getAllTypesSync();
  Stream<List<ShiftTypeEntity>> getDefaultShiftTypes();
  Future<int> getShiftTypeCount();
  Stream<ShiftTypeEntity?> getShiftTypeById(int id);
}

// 班次模板 DAO
abstract class ShiftTemplateDao {
  Future<int> insert(ShiftTemplate template);
  Future<void> update(ShiftTemplate template);
  Future<void> delete(ShiftTemplate template);
  Stream<List<ShiftTemplate>> getAllTemplates();
  Future<List<ShiftTemplate>> getAllTemplatesSync();
  Stream<List<ShiftTemplate>> getDefaultTemplates();
  Stream<ShiftTemplate?> getTemplateById(int id);
  Future<int> getTemplateCount();
}

// 基础闹钟 DAO
abstract class AlarmDao {
  Future<int> insert(Alarm alarm);
  Future<void> update(Alarm alarm);
  Future<void> delete(Alarm alarm);
  Stream<List<Alarm>> getAllAlarms();
  Stream<Alarm?> getAlarmById(int id);
  Stream<List<Alarm>> getEnabledAlarms();
  Future<void> updateEnabled(int id, bool enabled);
  Future<void> deleteById(int id);
  Future<List<Alarm>> getAllAlarmsSync();
  Future<void> deleteAll();
}

// 扩展闹钟 DAO
abstract class AlarmEntityDao {
  Future<int> insert(AlarmEntity alarm);
  Future<void> update(AlarmEntity alarm);
  Future<void> delete(AlarmEntity alarm);
  Stream<List<AlarmEntity>> getAllAlarms();
  Stream<AlarmEntity?> getAlarmById(int id);
  Stream<List<AlarmEntity>> getEnabledAlarms();
  Future<void> updateEnabled(int id, bool enabled);
  Future<void> disableAllAlarms();
  Future<void> deleteById(int id);
  Future<List<AlarmEntity>> getAllAlarmsSync();
  Future<void> deleteAll();
}

// 用户资料 DAO
abstract class UserProfileDao {
  Future<void> insert(UserProfile userProfile);
  Future<void> update(UserProfile userProfile);
  Future<UserProfile?> getUserProfile();
  Future<void> updateProfile(int id, String name, String imageUri, String email);
}

// 用户设置 DAO
abstract class UserSettingsDao {
  Future<UserSettings?> getUserSettings();
  Future<void> insert(UserSettings settings);
  Future<void> update(UserSettings settings);
  Future<void> updateThemeMode(int id, int themeMode);
  Future<void> updateLanguageMode(int id, int languageMode);
  Future<void> updateNotificationEnabled(int id, bool enabled);
  Future<void> updateNotificationAdvanceTime(int id, int minutes);
}
```

## 5. 数据库操作优化

### 5.1 批量操作
```dart
Future<void> insertMultipleShifts(List<Shift> shifts) async {
  final db = await _databaseHelper.database;
  final batch = db.batch();
  
  for (var shift in shifts) {
    batch.insert('shifts', shift.toMap());
  }
  
  await batch.commit(noResult: true);
}
```

### 5.2 事务处理
```dart
Future<void> transferShift(int fromId, int toId) async {
  final db = await _databaseHelper.database;
  await db.transaction((txn) async {
    await txn.rawUpdate(
      'UPDATE shifts SET shiftTypeId = ? WHERE id = ?',
      [toId, fromId]
    );
  });
}
```

## 6. 最佳实践

### 6.1 数据库初始化
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dbHelper = DatabaseHelper();
  await dbHelper.database;
  runApp(MyApp());
}
```

### 6.2 异常处理
```dart
Future<void> safeOperation(Future<void> Function() operation) async {
  try {
    await operation();
  } catch (e) {
    print('数据库操作错误: $e');
    // 错误处理逻辑
  }
}
```

## 7. 注意事项

1. 在主线程中避免耗时的数据库操作
2. 正确关闭数据库连接和流控制器
3. 定期备份重要数据
4. 处理并发访问问题
5. 注意 SQL 注入防护
6. 使用事务处理批量操作
7. 合理使用索引提升查询性能

## 8. 依赖配置

在 `pubspec.yaml` 中添加必要的依赖：
```yaml
dependencies:
  sqflite: ^2.3.0
  path: ^1.8.3
  path_provider: ^2.1.1
```

## 9. 维护建议

1. 定期检查数据库性能
2. 监控数据库大小
3. 优化查询语句
4. 及时更新数据库版本
5. 保持文档同步更新

此文档将随着数据库的更新而更新，请确保始终参考最新版本。 