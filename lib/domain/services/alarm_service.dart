import 'dart:async';
import '../../data/models/alarm.dart';
import '../../data/repositories/alarm_repository.dart';

class AlarmService {
  final AlarmRepository _alarmRepository;

  AlarmService(this._alarmRepository);

  // 获取闹钟流
  Stream<List<AlarmEntity>> get alarmsStream => _alarmRepository.alarmsStream;

  // 基础CRUD操作
  Future<List<AlarmEntity>> getAllAlarms() => _alarmRepository.getAll();
  
  Future<AlarmEntity?> getAlarmById(int id) => _alarmRepository.getById(id);

  // 添加新闹钟
  Future<int> addAlarm(AlarmEntity alarm) async {
    // 验证时间是否有效
    if (alarm.timeInMillis < DateTime.now().millisecondsSinceEpoch) {
      throw Exception('闹钟时间不能早于当前时间');
    }
    return _alarmRepository.insert(alarm);
  }

  // 更新闹钟
  Future<int> updateAlarm(AlarmEntity alarm) async {
    // 对于非重复闹钟，验证时间是否有效
    if (!alarm.repeat && alarm.timeInMillis < DateTime.now().millisecondsSinceEpoch) {
      throw Exception('闹钟时间不能早于当前时间');
    }
    return _alarmRepository.update(alarm);
  }

  // 删除闹钟
  Future<int> deleteAlarm(int id) => _alarmRepository.delete(id);

  // 获取所有启用的闹钟
  Future<List<AlarmEntity>> getEnabledAlarms() => 
    _alarmRepository.getEnabledAlarms();

  // 获取所有重复的闹钟
  Future<List<AlarmEntity>> getRepeatingAlarms() =>
    _alarmRepository.getRepeatingAlarms();

  // 获取指定时间范围内的闹钟
  Future<List<AlarmEntity>> getAlarmsByTimeRange(
    DateTime start,
    DateTime end,
  ) => _alarmRepository.getAlarmsByTimeRange(
    start.millisecondsSinceEpoch,
    end.millisecondsSinceEpoch,
  );

  // 更新闹钟启用状态
  Future<int> toggleAlarmEnabled(int id) async {
    final alarm = await getAlarmById(id);
    if (alarm == null) {
      throw Exception('闹钟不存在');
    }
    return _alarmRepository.updateAlarmEnabled(id, !alarm.enabled);
  }

  // 更新闹钟重复设置
  Future<int> updateAlarmRepeat(
    int id,
    bool repeat,
    List<int> repeatDays,
  ) async {
    if (repeat && repeatDays.isEmpty) {
      throw Exception('请选择重复日期');
    }
    
    int repeatDaysBits = 0;
    for (final day in repeatDays) {
      repeatDaysBits |= (1 << day);
    }
    
    return _alarmRepository.updateAlarmRepeat(id, repeat, repeatDaysBits);
  }

  // 获取下一个要触发的闹钟
  Future<AlarmEntity?> getNextAlarm() => _alarmRepository.getNextAlarm();

  // 批量删除闹钟
  Future<int> deleteAlarms(List<int> ids) => _alarmRepository.deleteAll(ids);

  void dispose() {
    _alarmRepository.dispose();
  }
} 