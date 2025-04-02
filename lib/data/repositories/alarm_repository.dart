import 'dart:async';
import '../database/daos/alarm_dao.dart';
import '../models/alarm.dart';
import 'base_repository.dart';

class AlarmRepository implements BaseRepository<AlarmEntity> {
  final AlarmEntityDao _alarmDao;
  final _alarmController = StreamController<List<AlarmEntity>>.broadcast();

  AlarmRepository(this._alarmDao);

  // 获取闹钟流，用于实时更新UI
  Stream<List<AlarmEntity>> get alarmsStream => _alarmController.stream;

  @override
  Future<List<AlarmEntity>> getAll() async {
    final alarms = await _alarmDao.getAllAlarms();
    _alarmController.add(alarms);
    return alarms;
  }

  @override
  Future<AlarmEntity?> getById(int id) async {
    return await _alarmDao.getAlarmById(id);
  }

  @override
  Future<int> insert(AlarmEntity alarm) async {
    try {
      print('AlarmRepository准备插入闹钟数据: ${alarm.toMap()}');
      final id = await _alarmDao.insertAlarm(alarm);
      print('AlarmRepository闹钟插入成功，ID: $id');
      getAll(); // 更新流
      return id;
    } catch (e) {
      print('AlarmRepository插入闹钟失败: $e');
      throw Exception('插入闹钟数据失败: $e');
    }
  }

  @override
  Future<int> update(AlarmEntity alarm) async {
    final result = await _alarmDao.updateAlarm(alarm);
    getAll(); // 更新流
    return result;
  }

  @override
  Future<int> delete(int id) async {
    final result = await _alarmDao.deleteAlarm(id);
    getAll(); // 更新流
    return result;
  }

  @override
  Future<int> deleteAll(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      count += await delete(id);
    }
    return count;
  }

  @override
  Future<int> count() async {
    return await _alarmDao.getAlarmCount();
  }

  // 特定的业务查询方法

  /// 获取所有启用的闹钟
  Future<List<AlarmEntity>> getEnabledAlarms() async {
    return await _alarmDao.getEnabledAlarms();
  }

  /// 获取所有重复的闹钟
  Future<List<AlarmEntity>> getRepeatingAlarms() async {
    return await _alarmDao.getRepeatAlarms();
  }

  /// 获取指定时间范围内的闹钟
  Future<List<AlarmEntity>> getAlarmsByTimeRange(
    int startTime,
    int endTime,
  ) async {
    final alarms = await _alarmDao.getAllAlarms();
    return alarms
        .where((alarm) =>
            alarm.timeInMillis >= startTime && alarm.timeInMillis <= endTime)
        .toList();
  }

  /// 更新闹钟启用状态
  Future<int> updateAlarmEnabled(int id, bool enabled) async {
    final alarm = await getById(id);
    if (alarm == null) return 0;

    return await update(alarm.copyWith(
      enabled: enabled,
      updateTime: DateTime.now().millisecondsSinceEpoch,
    ));
  }

  /// 更新闹钟重复设置
  Future<int> updateAlarmRepeat(
    int id,
    bool repeat,
    int repeatDays,
  ) async {
    final alarm = await getById(id);
    if (alarm == null) return 0;

    return await update(alarm.copyWith(
      repeat: repeat,
      repeatDays: repeatDays,
      updateTime: DateTime.now().millisecondsSinceEpoch,
    ));
  }

  /// 获取下一个要触发的闹钟
  Future<AlarmEntity?> getNextAlarm() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final alarms = await getEnabledAlarms();

    if (alarms.isEmpty) return null;

    // 对于重复闹钟，计算下一次触发时间
    AlarmEntity? nextAlarm;
    int nextTriggerTime = -1;

    for (final alarm in alarms) {
      int triggerTime;

      if (alarm.repeat) {
        triggerTime = _calculateNextRepeatTime(alarm);
      } else {
        triggerTime = alarm.timeInMillis;
        if (triggerTime < now) continue; // 跳过已过期的非重复闹钟
      }

      if (nextTriggerTime == -1 || triggerTime < nextTriggerTime) {
        nextTriggerTime = triggerTime;
        nextAlarm = alarm;
      }
    }

    return nextAlarm;
  }

  /// 计算重复闹钟的下一次触发时间
  int _calculateNextRepeatTime(AlarmEntity alarm) {
    final now = DateTime.now();
    final alarmTime = DateTime.fromMillisecondsSinceEpoch(alarm.timeInMillis);

    // 创建今天的闹钟时间
    final todayAlarmTime = DateTime(
      now.year,
      now.month,
      now.day,
      alarmTime.hour,
      alarmTime.minute,
    );

    // 如果今天的闹钟时间已过，从明天开始查找
    final startDay =
        todayAlarmTime.isBefore(now) ? now.add(const Duration(days: 1)) : now;

    // 查找下一个重复日
    for (int i = 0; i < 7; i++) {
      final checkDay = startDay.add(Duration(days: i));
      final weekday = checkDay.weekday % 7; // 0-6，0表示周日
      final weekdayBit = 1 << weekday;

      if (alarm.repeatDays & weekdayBit != 0) {
        final nextAlarmTime = DateTime(
          checkDay.year,
          checkDay.month,
          checkDay.day,
          alarmTime.hour,
          alarmTime.minute,
        );
        return nextAlarmTime.millisecondsSinceEpoch;
      }
    }

    // 如果没有找到下一个重复日（不应该发生），返回原始时间
    return alarm.timeInMillis;
  }

  void dispose() {
    _alarmController.close();
  }
}
