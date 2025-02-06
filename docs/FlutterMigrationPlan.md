# 排班助手Flutter迁移技术方案

## 目录
- [项目概述](#项目概述)
- [系统架构](#系统架构)
- [功能模块迁移计划](#功能模块迁移计划)
- [迁移步骤](#迁移步骤)
- [关键技术点](#关键技术点)
- [风险管理](#风险管理)
- [质量保证](#质量保证)
- [进度安排](#进度安排)
- [后续计划](#后续计划)
- [架构优化建议](#架构优化建议)

## 项目概述

### 项目背景
将现有Android原生排班助手应用迁移到Flutter框架，实现跨平台支持，提升开发效率和用户体验。

### 技术选型
- 框架：Flutter 3.x
- 开发语言：Dart
- 状态管理：Provider + Bloc
- 数据持久化：SQLite (sqflite)
- 原生通道：Method Channel

## 系统架构

### 整体架构
```
┌─────────────── Presentation Layer ───────────────┐
│  ┌─────────────┐  ┌─────────────┐  ┌─────────┐  │
│  │   Screens   │  │   Widgets   │  │  Blocs  │  │
│  └─────────────┘  └─────────────┘  └─────────┘  │
├─────────────── Domain Layer ──────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────┐  │
│  │  Services   │  │ Repository  │  │ Models  │  │
│  └─────────────┘  └─────────────┘  └─────────┘  │
├─────────────── Data Layer ────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────┐  │
│  │   SQLite    │  │Native Bridge│  │  APIs   │  │
│  └─────────────┘  └─────────────┘  └─────────┘  │
└─────────────────────────────────────────────────┘
```

### 目录结构
```
lib/
├── core/                 # 核心功能
│   ├── constants/        # 常量定义
│   ├── themes/           # 主题配置
│   ├── routes/          # 路由管理
│   └── utils/           # 工具类
├── data/                # 数据层
│   ├── models/          # 数据模型
│   ├── repositories/    # 数据仓库
│   ├── services/        # 业务服务
│   └── database/        # 数据库相关
│       ├── migrations/  # 数据库迁移脚本
│       ├── daos/        # 数据访问对象
│       └── entities/    # 数据库实体
├── presentation/        # 表现层
│   ├── screens/         # 页面
│   ├── widgets/         # 组件
│   └── blocs/           # 状态管理
├── platform/            # 平台特定代码
│   ├── android/         # Android原生代码
│   └── ios/             # iOS原生代码
└── main.dart            # 入口文件
```

## 功能模块迁移计划

### 核心模块

#### 班次管理模块
```dart
// 数据模型
class Shift {
  final int id;
  final String name;
  final DateTime startTime;
  final DateTime endTime;
  final int color;
  final int shiftTypeId;
  final DateTime updateTime;
  
  // ... 其他属性
}

// 状态管理
class ShiftBloc extends Cubit<ShiftState> {
  final ShiftRepository repository;
  
  Future<void> loadShifts() async {
    // ... 加载班次数据
  }
  
  Future<void> addShift(Shift shift) async {
    // ... 添加班次
  }
}

// UI实现
class ShiftCalendarScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ShiftBloc, ShiftState>(
      builder: (context, state) {
        return CustomCalendarView(
          shifts: state.shifts,
          onDaySelected: (date) => _handleDaySelect(date),
        );
      },
    );
  }
}
```

#### 闹钟管理模块
```dart
// 原生通道定义
class AlarmService {
  static const platform = MethodChannel('com.schedule.assistant/alarm');
  
  Future<void> setAlarm(AlarmData data) async {
    await platform.invokeMethod('setAlarm', data.toJson());
  }
}

// 闹钟管理界面
class AlarmScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AlarmBloc, AlarmState>(
      listener: (context, state) {
        // ... 处理状态变化
      },
      builder: (context, state) {
        return AlarmList(
          alarms: state.alarms,
          onToggle: (alarm) => _toggleAlarm(alarm),
        );
      },
    );
  }
}
```

### 数据持久化方案

#### 1. SQLite数据库设计
```dart
// 数据库提供者
abstract class DatabaseProvider {
  Future<Database> getDatabase();
  Future<void> migrate();
  Future<void> close();
}

// SQLite实现
class SQLiteDatabaseProvider implements DatabaseProvider {
  static Database? _database;
  
  @override
  Future<Database> getDatabase() async {
    if (_database != null) return _database!;
    
    _database = await openDatabase(
      'schedule_assistant.db',
      version: 102, // 与Android版本保持一致
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    
    return _database!;
  }
  
  Future<void> _onCreate(Database db, int version) async {
    // 创建数据库表
    await db.execute('''
      CREATE TABLE IF NOT EXISTS shift_types (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        startTime TEXT,
        endTime TEXT,
        color INTEGER NOT NULL,
        isDefault INTEGER NOT NULL,
        updateTime INTEGER NOT NULL
      )
    ''');
    // ... 其他表的创建
  }
  
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 实现与Android版本相同的迁移策略
    if (oldVersion < 2) {
      await db.execute(
        "ALTER TABLE shifts ADD COLUMN updateTime INTEGER NOT NULL DEFAULT 0"
      );
    }
    // ... 其他版本的迁移
  }
}

// DAO实现示例
class ShiftDao {
  final DatabaseProvider _provider;
  
  Future<List<Shift>> getAllShifts() async {
    final db = await _provider.getDatabase();
    final List<Map<String, dynamic>> maps = await db.query('shifts');
    return List.generate(maps.length, (i) => Shift.fromMap(maps[i]));
  }
  
  Future<void> insertShift(Shift shift) async {
    final db = await _provider.getDatabase();
    await db.insert('shifts', shift.toMap());
  }
}
```

#### 2. 数据迁移策略

##### 2.1 版本兼容性
- 保持与Android版本相同的数据库版本号(102)
- 实现所有历史版本的迁移脚本
- 提供数据库降级方案

##### 2.2 数据迁移流程
1. 数据备份
   - 在迁移前自动备份数据库
   - 提供手动备份功能
   
2. 增量迁移
   - 按版本号顺序执行迁移脚本
   - 保证迁移过程的原子性
   
3. 数据验证
   - 迁移后进行数据完整性检查
   - 提供数据修复工具
   
4. 回滚机制
   - 迁移失败时自动回滚
   - 支持手动回滚到指定版本

##### 2.3 数据同步
- 实现增量同步机制
- 处理数据冲突
- 提供手动同步功能

## 解耦与迁移策略

### 1. 领域模型解耦

#### 1.1 核心领域模型定义
```dart
// 定义领域接口
abstract class IShift {
  int getId();
  String getName();
  DateTime getStartTime();
  DateTime getEndTime();
  int getColor();
  int getShiftTypeId();
  DateTime getUpdateTime();
}

// 统一实现
class ShiftImpl implements IShift {
  final int id;
  final String name;
  final DateTime startTime;
  final DateTime endTime;
  final int color;
  final int shiftTypeId;
  final DateTime updateTime;
  
  // 构造函数和方法实现
}
```

#### 1.2 业务规则抽象
```dart
// 定义业务规则接口
abstract class IShiftService {
  Future<List<IShift>> getShifts();
  Future<void> addShift(IShift shift);
  Future<void> updateShift(IShift shift);
  Future<void> deleteShift(int id);
  Future<List<IShift>> getShiftsByDateRange(DateTime start, DateTime end);
}

// SQLite实现
class SQLiteShiftService implements IShiftService {
  final ShiftDao _shiftDao;
  
  // 实现方法
}
```

### 2. 数据访问层

#### 2.1 Repository模式
```dart
abstract class IShiftRepository {
  Future<List<Shift>> fetchShifts();
  Future<void> saveShift(Shift shift);
  Future<void> updateShift(Shift shift);
  Future<void> deleteShift(int id);
}

// SQLite实现
class SQLiteShiftRepository implements IShiftRepository {
  final ShiftDao _shiftDao;
  
  // 实现方法
}
```

### 3. 渐进式迁移流程

#### 3.1 准备阶段（4周）
1. 数据库迁移准备（1周）
   - 编写数据库迁移脚本
   - 实现数据验证工具
   - 测试迁移流程

2. 接口定义与抽象（1周）
   - 定义核心领域模型接口
   - 定义业务规则接口
   - 定义数据访问接口

3. 依赖注入框架搭建（1周）
   - 实现依赖注入容器
   - 配置模块注入规则
   - 测试依赖注入

4. 桥接层实现（1周）
   - 实现Android-Flutter通信
   - 实现数据转换
   - 错误处理机制

#### 3.2 核心功能迁移（8周）

1. 数据层迁移（2周）
```dart
// 数据迁移管理器
class DataMigrationManager {
  Future<void> migrateShifts() async {
    // 1. 读取原有数据
    // 2. 转换数据格式
    // 3. 写入新存储
    // 4. 验证数据一致性
  }
  
  Future<void> rollback() async {
    // 回滚机制
  }
}
```

2. 业务层迁移（3周）
```dart
// 业务规则迁移
class BusinessRuleMigrator {
  Future<void> migrateRules() async {
    // 1. 提取业务规则
    // 2. 实现新接口
    // 3. 单元测试验证
  }
}
```

3. UI层迁移（3周）
   - 实现基础UI组件
   - 页面逐步替换
   - 保持双向兼容

### 4. 解耦原则

#### 4.1 模块间通信
```dart
// 定义事件总线接口
abstract class IEventBus {
  void emit(String event, dynamic data);
  Stream<T> on<T>(String event);
}

// 实现模块间通信
class EventBusImpl implements IEventBus {
  // 实现细节
}
```

#### 4.2 依赖倒置
```dart
// 依赖注入配置
@module
class AppModule {
  @provides
  IShiftRepository provideShiftRepository() {
    return isFlutter 
      ? FlutterShiftRepository()
      : AndroidShiftRepository();
  }
}
```

### 5. 质量保证

#### 5.1 测试策略
```dart
// 契约测试
abstract class RepositoryContract {
  Future<void> testBasicOperations();
  Future<void> testDataConsistency();
  Future<void> testErrorHandling();
}

class RepositoryTest implements RepositoryContract {
  // 测试实现
}
```

#### 5.2 监控指标
- 接口响应时间
- 数据一致性
- 内存使用
- 崩溃率

### 6. 回滚策略

#### 6.1 功能开关
```dart
class FeatureToggle {
  static bool useFlutterUI = false;
  static bool useFlutterData = false;
  
  static void rollbackToAndroid() {
    useFlutterUI = false;
    useFlutterData = false;
  }
}
```

#### 6.2 数据回滚
- 数据备份机制
- 版本控制
- 增量回滚

### 7. 进度控制

#### 7.1 关键节点
1. 接口定义完成
2. 数据迁移验证
3. 核心功能迁移
4. 全量切换测试

#### 7.2 质量门禁
- 代码覆盖率 > 80%
- 性能指标达标
- 无阻塞性bug
- 用户体验评分

## 迁移步骤

### 准备阶段（2周）
1. 环境搭建
   - Flutter SDK安装
   - IDE配置
   - 项目初始化

2. 基础框架搭建
   - 路由系统
   - 主题配置
   - 依赖注入
   - 工具类迁移

### 核心功能迁移（6周）

#### 第1-2周：数据层迁移
- 数据模型定义
- Repository模式实现
- 本地存储迁移
- 原生通道搭建

#### 第3-4周：UI层迁移
- 班次管理界面
- 日历组件
- 闹钟管理界面
- 统计分析界面

#### 第5-6周：业务逻辑迁移
- 状态管理实现
- 业务逻辑迁移
- 原生功能对接
- 数据同步实现

### 优化阶段（2周）
- 性能优化
- UI/UX改进
- 错误处理
- 单元测试

### 测试发布（2周）
- 功能测试
- 兼容性测试
- 性能测试
- 应用发布

## 关键技术点

### 状态管理
```dart
// 使用Provider + Bloc模式
void main() {
  runApp(
    MultiProvider(
      providers: [
        BlocProvider(create: (_) => ShiftBloc()),
        BlocProvider(create: (_) => AlarmBloc()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: MyApp(),
    ),
  );
}
```

### 原生功能集成
```dart
// 原生通道封装
class PlatformService {
  static const platform = MethodChannel('com.schedule.assistant/platform');
  
  Future<void> requestPermission(String permission) async {
    try {
      final granted = await platform.invokeMethod('requestPermission', {
        'permission': permission,
      });
      return granted;
    } catch (e) {
      throw PlatformException(code: 'PERMISSION_DENIED');
    }
  }
}
```

### 主题系统
```dart
class AppTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
      // ... 其他主题配置
    );
  }
  
  static ThemeData dark() {
    // ... 深色主题配置
  }
}
```

## 风险管理

### 技术风险
- 原生功能兼容性
- 性能优化
- 数据迁移

### 进度风险
- 学习曲线
- 功能复杂度
- 测试时间

### 应对策略
1. 技术预研
2. 分阶段实施
3. 及时调整计划
4. 保持代码质量

## 质量保证

### 测试策略
- 单元测试
- Widget测试
- 集成测试
- 性能测试

### 代码规范
- Dart代码规范
- 命名规范
- 注释规范
- 代码审查

## 进度安排

### 里程碑
1. Week 1-2: 基础框架搭建
2. Week 3-8: 核心功能迁移
3. Week 9-10: 优化和测试
4. Week 11-12: 应用发布

### 交付物
1. Flutter项目代码
2. 技术文档
3. 测试报告
4. 发布包

## 后续计划

### 功能扩展
- iOS版本适配
- 新功能开发
- 性能优化

### 维护计划
- 定期更新
- Bug修复
- 用户反馈

## 更新记录

| 日期 | 版本 | 更新内容 | 更新人 |
|------|------|----------|--------|
| 2024-01-15 | v1.0 | 创建技术方案文档 | xiaolin0429 | 

## 架构优化建议

### 当前架构分析

#### 现存耦合点
1. **数据层与领域层耦合**
   - `data/models` 和 `domain/entities` 存在职责重叠
   - 数据转换逻辑分散在不同层级
   - 缺乏统一的数据映射策略

2. **业务逻辑分散**
   - `data/services` 和 `domain/usecases` 的职责边界模糊
   - 业务规则可能在不同层级重复实现
   - 缺乏统一的业务规则管理

3. **平台特定代码管理**
   - `platform` 目录与业务逻辑耦合
   - 缺乏统一的平台抽象层
   - 跨平台功能实现不够清晰

### 优化方案

#### 改进后的目录结构
```
scheduling_assistant/
├── lib/
│   ├── app/                    # 应用程序核心
│   │   ├── platform/          # 平台抽象层
│   │   │   ├── interfaces/    # 平台接口定义
│   │   │   └── implementations/# 平台实现
│   │   └── ... 
│   ├── domain/                 # 领域层（核心业务逻辑）
│   │   ├── entities/          # 纯粹的领域实体
│   │   ├── value_objects/     # 值对象
│   │   ├── interfaces/        # 核心接口定义
│   │   └── usecases/         # 用例（纯业务逻辑）
│   ├── infrastructure/        # 基础设施层
│   │   ├── datasources/      # 数据源
│   │   ├── mappers/          # 数据映射器
│   │   ├── models/           # 数据传输对象(DTO)
│   │   └── repositories/     # 仓库实现
│   └── presentation/         # 表现层
│       ├── common/           # 共享UI组件
│       └── features/         # 按功能模块组织的UI
```

#### 核心改进点

1. **强化领域驱动设计(DDD)**
```dart
// domain/entities/shift.dart
class Shift {
  final ShiftId id;         // 值对象
  final ShiftName name;     // 值对象
  final TimeRange period;   // 值对象
  final ShiftType type;     // 枚举或值对象
  
  // 领域行为
  bool canOverlapWith(Shift other) {
    // 业务规则
  }
}
```

2. **引入防腐层模式**
```dart
// infrastructure/mappers/shift_mapper.dart
class ShiftMapper {
  // 领域实体 -> DTO
  static ShiftDTO toDTO(Shift domain) {
    // 转换逻辑
  }
  
  // DTO -> 领域实体
  static Shift toDomain(ShiftDTO dto) {
    // 转换逻辑
  }
}
```

3. **统一平台抽象**
```dart
// core/platform/interfaces/i_platform_alarm.dart
abstract class IPlatformAlarm {
  Future<void> scheduleAlarm(AlarmSettings settings);
  Future<void> cancelAlarm(String id);
}
```

4. **特性模块化**
```dart
// presentation/features/shift/pages/shift_list_page.dart
class ShiftListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<ShiftBloc>(),
      child: ShiftListView(),
    );
  }
}
```

### 实施建议

考虑到项目实际情况，我们建议采用**谨慎优化**的策略：

1. **保持现有架构基础**
   - 避免大规模重构带来的风险
   - 确保迁移过程的平稳进行
   - 维持团队开发效率

2. **渐进式改进**
   - 新功能采用优化后的架构
   - 维护过程中逐步重构
   - 设定清晰的架构规范

3. **优先级排序**
   - 第一阶段：实现平台抽象层
   - 第二阶段：引入数据映射器
   - 第三阶段：规范化特性模块
   - 第四阶段：完善领域模型

4. **注意事项**
   - 确保向后兼容性
   - 完善单元测试覆盖
   - 及时更新技术文档
   - 做好团队培训

### 收益与成本分析

1. **收益**
   - 降低系统耦合度
   - 提高代码可维护性
   - 便于功能扩展
   - 提升测试效率

2. **成本**
   - 增加初始开发时间
   - 提高学习曲线
   - 需要更多的代码维护
   - 可能影响开发节奏

3. **风险控制**
   - 制定详细的重构计划
   - 建立健全的测试机制
   - 保持频繁的代码审查
   - 做好版本控制管理
``` 